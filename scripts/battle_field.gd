class_name BattleField
extends Node2D

enum ActionTaken{ATTACK, MOVE, WAIT}

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var enemy_field : PlayerField = $"../MarginContainer2/EnemyField"
@onready var atb_bar : TurnScale = $"../TurnScale"

var attacker_card : Card

func on_card_turn(card:Card):
	# first color the selected card
	card.set_outline(Card.Outline.CURRENT)	
	attacker_card = card
	attack_visualize_front(card, 4)

# for type archer
func attack_any():
	pass

func reset_vizualize():
	if attacker_card:
		attacker_card.set_outline(Card.Outline.NONE)
		for slot : CardSlot in enemy_field.grid:
			if !slot.is_empty():
				slot.card_ref.set_outline(Card.Outline.NONE)

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
	if !attacker_card: return false
	
	var card = enemy_field.grid[slot_idx].card_ref
	if card:
		match card.card_state:
			Card.Outline.ENEMY_FULL:
				var damage = attacker_card.unit.attack * attacker_card.number				
				make_turn.rpc(multiplayer.get_unique_id(), 
				{	
					"action":ActionTaken.ATTACK,
					"target" : card.slot,
					"damage" : damage
				})
				return true
		return true
	return false

func move_to_slot(slot:CardSlot):
	if !attacker_card or !slot.is_empty(): return
	make_turn.rpc(multiplayer.get_unique_id(), 
				{	
					"action":ActionTaken.MOVE,
					"target" : slot.slot_number,
				})

func take_damage(target_card : Card, damage: int):
	var target_overall_hp = (target_card.number - 1) * target_card.unit.health + target_card.current_health
	var remaining_hp = max(target_overall_hp - damage, 0)
	
	var units_remain = remaining_hp / target_card.unit.health
	var health_remain = remaining_hp % target_card.unit.health

	target_card.number = units_remain + int(health_remain > 0)
	target_card.current_health = health_remain
	

@rpc("any_peer", "call_local","reliable")
func make_turn(send_id:int, turn_desc : Dictionary): # Format {"action":ActionTaken,"target":int, "?damage":int}
	var recv_id = multiplayer.get_unique_id()
	var action : ActionTaken = turn_desc["action"]
	var target_field : PlayerField = player_field
	var opposite_field : PlayerField = enemy_field
	var invert : bool = true
	if recv_id == send_id:
		target_field = enemy_field # Called from and on command host
		opposite_field = player_field
		invert = false
	
	match action:
		ActionTaken.MOVE:
			var target_slot : int = turn_desc["target"]
			var slot : CardSlot = opposite_field.get_at(target_slot, invert)
			var attacker:TurnScale.CardRef = atb_bar.first()
			opposite_field.get_at(attacker.ref.slot, !invert).reset_card()
			slot.set_card(attacker.ref)
			
			var new_first : TurnScale.CardRef = atb_bar.action()
			reset_vizualize()
			if new_first.belongs_to_player:
				on_card_turn(new_first.ref)
			else:
				attacker_card = null

		ActionTaken.ATTACK: # This is called on enemy turn, so everything is mirrored
			var attacker:TurnScale.CardRef = atb_bar.first()
			var damage : int = turn_desc["damage"]
			var target_slot : int = turn_desc["target"]
			var target : CardSlot = target_field.get_at(target_slot, invert) # inverted
			var target_card : Card = target.card_ref			
			
			var before : int = target_card.number
			take_damage(target_card, damage)
			var units_killed = before - target_card.number
			
			print("{unit_a} attacked {unit_t}, dealt {dmg} damage, killed {kill}"
				.format({"unit_a":attacker.ref.unit.tag,
				"unit_t":target.card_ref.unit.tag,
				"dmg":damage,
				"kill":units_killed}))
			
			if target_card.number == 0: # Remove
				atb_bar.trim_card(target_card)
				target_card.queue_free()
			
			var new_first : TurnScale.CardRef = atb_bar.action()
			reset_vizualize()
			if new_first.belongs_to_player:
				on_card_turn(new_first.ref)
			else:
				attacker_card = null
	
