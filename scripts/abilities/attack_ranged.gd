class_name AttackRanged
extends Attack

var grid_ref : Array[CardSlot] = []

# Viz passive
func init(_parent : Node) -> void:
	pass

func slot_not_empty(slot : CardSlot) -> bool:
	return !slot.is_empty()

func not_free_shot(field : PlayerField):
	for slot : CardSlot in field.grid.filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.ENEMY_PENALTY

# Called only from attacker
func visualize(caster : Card, _target : Card, battlefield : BattleField) -> void:
	var position = caster.slot
	var field : PlayerField = battlefield.enemy_field
	grid_ref = field.grid
	
	var slot_front = field.get_in_front(position)
	var free_shot = slot_front == null || slot_front.is_empty()
	
	if !free_shot: not_free_shot(field); return;
	
	# Radius is global for now
	# Front row:
	for slot : CardSlot in field.grid.slice(0, field.field_width).filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL

	# Back row:
	for slot : CardSlot in field.grid.slice(field.field_width, field.field_width * 2).filter(slot_not_empty):
		var slot_in_front = field.get_in_front(slot.slot_number)
		slot.card_ref.card_state = \
			Card.CardSelection.ENEMY_FULL if slot_in_front.is_empty() else \
			Card.CardSelection.ENEMY_PENALTY


func reset_visualize() -> void:
	for slot : CardSlot in grid_ref.filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.NONE

func validate(_caster : Card, target : Card, _battlefield : BattleField) -> bool:
	return target.card_state == Card.CardSelection.ENEMY_PENALTY || \
	target.card_state == Card.CardSelection.ENEMY_FULL

func predict(caster : Card, target : Card, _battlefield : BattleField) -> Dictionary:
	var damage = caster.unit.attack * caster.number
	if target.card_state == Card.CardSelection.ENEMY_PENALTY: damage /= 2
	
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
