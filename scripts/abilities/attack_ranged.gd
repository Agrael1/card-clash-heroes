class_name AttackRanged
extends Attack

var grid_ref : Array[CardSlot] = []

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
	
	var slot_front = battlefield.player_field.get_in_front(position)
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
