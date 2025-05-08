class_name BattleField
extends Node2D

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var enemy_field : PlayerField = $"../MarginContainer2/EnemyField"

var attacker_card : Card

func on_card_turn(card:Card):
	# first color the selected card
	card.set_outline(Card.Outline.CURRENT)	
	attacker_card = card
	attack_visualize_front(card, 4)

# for type archer
func attack_any():
	pass

# for fighter
func attack_visualize_front(card:Card, radius:int):
	var position = card.slot
	
	var offset = enemy_field.field_width
	var boundary_low = max(position - radius, 0) + offset
	var boundary_high = min(position + radius, enemy_field.field_width) + offset
	# get front row of the enemy field
	var enemy_row = enemy_field.grid.slice(boundary_low, boundary_high)
	for slot : CardSlot in enemy_row:
		if !slot.is_empty():
			slot.card_ref.set_outline(Card.Outline.ENEMY_FULL)

func try_attack_at(slot_idx:int)->bool:
	var card = enemy_field.grid[slot_idx].card_ref
	if card:
		match card.card_state:
			Card.Outline.ENEMY_FULL:
				# do a full damage
				var unit_attacker = attacker_card.unit
				var unit_target = card.unit
				var target_count = card.number
				
				var damage = min(unit_attacker.attack * attacker_card.number, target_count * unit_target.health)
				var killed_units = min(int(floor(damage / float(unit_target.health))), target_count)
				card.current_health -= damage - killed_units * unit_target.health
				card.number -= killed_units
				
				print("{unit_a} attacked {unit_t}, dealt {dmg} damage, killed {kill}"
				.format({"unit_a":unit_attacker.tag,
				"unit_t":unit_target.tag,
				"dmg":damage,
				"kill":killed_units}))
				
				if card.number == 0:
					card.queue_free()
					enemy_field.grid[slot_idx].card_ref = null
				
				return true
			
		
		return true
	return false

@rpc("any_peer","reliable")
func turn(unique_id:int, slot:int):
	pass
