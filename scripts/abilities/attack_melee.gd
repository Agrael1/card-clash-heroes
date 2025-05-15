class_name AttackMelee
extends Attack

const RADIUS = 4
var grid_ref : Array[CardSlot] = []

# Viz passive
func init(_parent : Node) -> void:
	pass

func slot_not_empty(slot : CardSlot) -> bool:
	return !slot.is_empty()

# Called only from attacker
func visualize(caster : Card, _target : Card, battlefield : BattleField) -> void:
	var position = caster.slot
	var field : PlayerField = battlefield.enemy_field
	grid_ref = field.grid
	
	
	# Radius is 4 
	# Front row: the slots are mirrored, so slot 0 is in front of field.field_width - 1
	var mirror_pos = field.field_width - position - 1
	var start_front = max(mirror_pos - RADIUS, 0)
	var end_front = min(mirror_pos + RADIUS, field.field_width)
	
	for slot : CardSlot in field.grid.slice(start_front, end_front).filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL

	# Back row:
	for slot : CardSlot in field.grid.slice(start_front + 1 + field.field_width, end_front - 1 + field.field_width).filter(slot_not_empty):
		var slot_in_front = field.get_in_front(slot.slot_number)
		if !slot_in_front.is_empty(): continue
		slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL

func reset_visualize() -> void:
	for slot : CardSlot in grid_ref.filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.NONE

func validate(_caster : Card, target : Card, _battlefield : BattleField) -> bool:
	return target.card_state == Card.CardSelection.ENEMY_FULL

func predict(caster : Card, target : Card, _battlefield : BattleField) -> Dictionary:
	var damage = caster.unit.attack * caster.number	
	var damage_result = target.calc_damage(damage)
	return {"damage":damage_result[2]}

# Called on both attacker and defender
func apply(caster : Card, target : Card, battlefield : BattleField, state : Dictionary) -> void:
	var damage_result = target.set_damage(state["damage"])
	var clog = battlefield.combat_log
	
	if !target.is_enemy():
		clog.add_combat_event("Your {unit_a} attacked enemy {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":target.unit.tag.to_upper(),
			"dmg":damage_result[3],
			"kill":damage_result[2]}))
	else:
		clog.add_combat_event("Enemy {unit_a} attacked your {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":target.unit.tag.to_upper(),
			"dmg":damage_result[3],
			"kill":damage_result[2]}))
			
	if target.number == 0:
		battlefield.atb_bar.trim_card(target)
		grid_ref[target.slot].reset_card()
		target.free()
