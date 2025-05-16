class_name AttackMelee
extends Attack

const RADIUS = 4
var grid_ref : Array[CardSlot] = []

# Viz passive
func slot_not_empty(slot : CardSlot) -> bool:
	return !slot.is_empty()

# Called only from attacker
func visualize(caster : Card, _target : Card, battlefield : BattleField) -> void:
	var position = caster.slot
	var field : PlayerField = battlefield.enemy_field
	grid_ref = field.grid
	
	var slot_front = battlefield.player_field.get_in_front(position)
	if slot_front && !slot_front.is_empty():
		return
	
	var radius = RADIUS
	if position > battlefield.player_field.field_width:
		radius -= 1
		position %=  battlefield.player_field.field_width
	
	# Radius is 4 
	# Front row: the slots are mirrored, so slot 0 is in front of field.field_width - 1
	var mirror_pos = field.field_width - position - 1
	var start_front = max(mirror_pos - radius, 0)
	var end_front = min(mirror_pos + radius, field.field_width)
	
	for slot : CardSlot in field.grid.slice(start_front, end_front).filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL

	print(str(start_front + 1 + field.field_width) + ":" + str(end_front - 1 + field.field_width))
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
	
