class_name AttackMelee
extends Attack

const RADIUS = 3
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
	if position >= battlefield.player_field.field_width:
		radius -= 1
		position %= battlefield.player_field.field_width
	
	var mirror_front = field.field_width - position - 1

	# Make triangular attack. Each row reduce the radius by 1.
	var slice_start = mirror_front - radius
	var slice_end = mirror_front + radius + 1
	for i in range(0, field.field_height):
		var row_start = max(slice_start, 0)
		var row_end = min(slice_end, field.field_width)
		for slot : CardSlot in field.grid.slice(row_start + field.field_width * i, row_end + field.field_width * i).filter(slot_not_empty):
			var slot_in_front = field.get_in_front(slot.slot_number)
			if slot_in_front && !slot_in_front.is_empty(): continue
			slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL
			
		slice_start += 1
		slice_end -= 1
		



	#var start_front = max(mirror_front - radius, 0)
	#var end_front = min(mirror_front + radius - 1, field.field_width)
	#
	#var start_back = max(mirror_back_pos - radius + 1, field.field_width)
	#var end_back = min(mirror_back_pos + radius, 2 * field.field_width)
	#
	#for slot : CardSlot in field.grid.slice(start_front, end_front).filter(slot_not_empty):
		#slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL
#
	## Back row:
	#for slot : CardSlot in field.grid.slice(start_back, end_back).filter(slot_not_empty):
		#var slot_in_front = field.get_in_front(slot.slot_number)
		#if !slot_in_front.is_empty(): continue
		#slot.card_ref.card_state = Card.CardSelection.ENEMY_FULL

func reset_visualize() -> void:
	for slot : CardSlot in grid_ref.filter(slot_not_empty):
		slot.card_ref.card_state = Card.CardSelection.NONE

func validate(_caster : Card, target : Card, _battlefield : BattleField) -> bool:
	return target.card_state == Card.CardSelection.ENEMY_FULL

func predict(caster : Card, target : Card, _battlefield : BattleField) -> Dictionary:
	var damage = caster.unit.attack * caster.number	
	var damage_result = target.calc_damage(damage)
	return {"damage":damage_result[2]}
	
