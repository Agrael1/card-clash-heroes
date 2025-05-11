class_name BattleField
extends Node2D

enum ActionTaken{ATTACK, MOVE, WAIT}

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var enemy_field : PlayerField = $"../MarginContainer2/EnemyField"
@onready var atb_bar : TurnScale = $"../TurnScale"
@onready var wait_button : Button = $"../FloatingMenu/Wait"
@onready var end_screen : GameOver = $"../GameOver"

var attacker_card : Card

func on_card_turn(card:Card):
	# first color the selected card
	card.set_outline(Card.Outline.CURRENT)
	wait_button.disabled = false
	
	attacker_card = card
	if card.unit.meele:
		attack_visualize_front(card, 4)
	else:
		attack_visualize_archer(card)

func reset_vizualize():
	if attacker_card:
		attacker_card.set_outline(Card.Outline.NONE)
		for slot : CardSlot in enemy_field.grid:
			if !slot.is_empty():
				slot.card_ref.set_outline(Card.Outline.NONE)

# for fighter
func attack_visualize_front(card:Card, radius:int):
	var position = card.slot % player_field.field_width
	radius -= card.slot / player_field.field_width
	
	# Obstructed
	if card.slot > player_field.field_width && \
	!player_field.get_at(card.slot - player_field.field_width).is_empty():
		return
	
	var offset = enemy_field.field_width
	var boundary_low = max(position - radius, 0) + offset
	var boundary_high = min(position + radius, enemy_field.field_width) + offset
	
	var boundary_low_back = max(position - radius - 1, 0)
	var boundary_high_back = min(position + radius - 1, enemy_field.field_width)
	# get front row of the enemy field
	var enemy_front_row = enemy_field.grid.slice(boundary_low, boundary_high)
	for slot : CardSlot in enemy_front_row:
		if !slot.is_empty():
			slot.card_ref.set_outline(Card.Outline.ENEMY_FULL)
			continue
		
		# get back row
		var back_slot_n = slot.slot_number - offset
		if back_slot_n >= boundary_low_back and back_slot_n <= boundary_high_back: # one less
			var back_slot = enemy_field.get_at(back_slot_n)
			if !back_slot.is_empty(): # back line attack
				back_slot.card_ref.set_outline(Card.Outline.ENEMY_FULL)


func attack_visualize_archer(card:Card):
	var position = card.slot % player_field.field_width
	var free_shot = card.slot < player_field.field_width ||\
	 player_field.get_at(card.slot - player_field.field_width).is_empty()
	
	for slot : CardSlot in enemy_field.grid.slice(enemy_field.field_width, enemy_field.field_width * 2):
		var slot_back = enemy_field.get_at(slot.slot_number - enemy_field.field_width)
		if !slot.is_empty():
			slot.card_ref.set_outline(Card.Outline.ENEMY_FULL if free_shot else Card.Outline.ENEMY_PENALTY)
			if !slot_back.is_empty():
				slot_back.card_ref.set_outline(Card.Outline.ENEMY_PENALTY)
			continue
		
		# No one in front
		if !slot_back.is_empty():
			slot_back.card_ref.set_outline(Card.Outline.ENEMY_FULL if free_shot else Card.Outline.ENEMY_PENALTY)
		

func try_attack_at(slot_idx:int)->bool:
	if !attacker_card: return false
	
	var card = enemy_field.grid[slot_idx].card_ref
	if card:
		var damage = attacker_card.unit.attack * attacker_card.number				
		make_turn.rpc(multiplayer.get_unique_id(), 
		{	
			"action":ActionTaken.ATTACK,
			"target" : card.slot,
			"damage" : damage if card.card_state == Card.Outline.ENEMY_FULL 
			else max(damage / 2, 1)
		})
		return true
	return false

func move_to_slot(slot:CardSlot):
	if !attacker_card or !slot.is_empty(): return
	make_turn.rpc(multiplayer.get_unique_id(), 
				{	
					"action":ActionTaken.MOVE,
					"target" : slot.slot_number,
				})

func wait():
	if !attacker_card: return
	make_turn.rpc(multiplayer.get_unique_id(), 
				{	
					"action":ActionTaken.WAIT
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
			opposite_field.get_at(attacker.ref.slot, invert).reset_card()
			slot.set_card(attacker.ref)
			
			atb_bar.action()

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
				target.reset_card()
				target_card.queue_free()
				
				
				# Check win condition
				if attacker.belongs_to_player: # We may win
					if enemy_field.is_empty():
						end_screen.win()
				else: # We might have lost
					if player_field.is_empty():
						end_screen.loose()
					
			
			atb_bar.action()

		ActionTaken.WAIT:
			atb_bar.wait()

	# Exec for all
	var new_first : TurnScale.CardRef = atb_bar.first()
	reset_vizualize()
	if new_first.belongs_to_player:
		on_card_turn(new_first.ref)
		wait_button.disabled = false
	else:
		attacker_card = null
		wait_button.disabled = true


func _on_wait_pressed() -> void:
	wait()
