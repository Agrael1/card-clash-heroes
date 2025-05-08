class_name BattleField
extends Node2D

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var enemy_field : PlayerField = $"../MarginContainer2/EnemyField"

var attacker_card : Card

func on_card_turn(card:Card):
	# first color the selected card
	card.set_outline(Card.Outline.CURRENT)	
	attacker_card = card
	attack_front(card, 4)

# for type archer
func attack_any():
	pass

# for fighter
func attack_front(card:Card, radius:int):
	var position = card.slot
	
	var offset = enemy_field.field_width
	var boundary_low = max(position - radius, 0) + offset
	var boundary_high = min(position + radius, enemy_field.field_width) + offset
	# get front row of the enemy field
	var enemy_row = enemy_field.grid.slice(boundary_low, boundary_high)
	for slot : CardSlot in enemy_row:
		if !slot.is_empty():
			slot.card_ref.set_outline(Card.Outline.ENEMY)

	

@rpc("any_peer","reliable")
func turn(unique_id:int, slot:int):
	pass
