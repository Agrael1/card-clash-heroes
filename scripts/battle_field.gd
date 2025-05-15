class_name BattleField
extends Node2D

enum ActionTaken{ATTACK, MOVE, WAIT, ABILITY}

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var enemy_field : PlayerField = $"../MarginContainer2/EnemyField"
@onready var atb_bar : TurnScale = $"../TurnScale"
@onready var wait_button : Button = $"../FloatingMenu/Wait"
@onready var end_screen : GameOver = $"../GameOver"
@onready var combat_log : CombatLog = $"../CombatLog"
@onready var tooltip : Tooltip = $"../Tooltip"

var attacker_card : Card

func _process(_delta: float) -> void:
	if tooltip.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip.position = mouse_pos + Vector2(10, 10) 

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				tooltip.visible = false

func on_card_turn(card:Card):
	# first color the selected card
	card.set_outline(Card.Outline.CURRENT)
	wait_button.disabled = false
	wait_button.text = "Wait"
	
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
	if card.slot >= player_field.field_width && \
	!player_field.get_at(card.slot - player_field.field_width).is_empty():
		return
	
	var offset = enemy_field.field_width
	var boundary_low = max(position - radius, 0) + offset
	var boundary_high = min(position + radius, enemy_field.field_width) + offset
	
	var boundary_low_back = max(position - radius + 1, 0)
	var boundary_high_back = min(position + radius - 1, enemy_field.field_width)
	
	print(str(boundary_low_back) + ":" + str(boundary_high_back) + ":" + str(position))
	
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
		

# abilities
func try_attack_at(slot_idx:int)->bool:
	if !attacker_card: return false
	
	var card = enemy_field.grid[slot_idx].card_ref
	if card:
		# check if we can deal damage
		if attacker_card.unit.meele and card.card_state == Card.Outline.NONE: # can't reach
			return false
		
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
	# Calculate total current HP across all units
	var target_overall_hp = (target_card.number - 1) * target_card.unit.health + target_card.current_health
	
	# Apply damage, with a minimum of 0 HP
	var remaining_hp = max(target_overall_hp - damage, 0)
	
	# Calculate how many full units we can have
	var units_remain = int(remaining_hp / target_card.unit.health)
	
	# Calculate remaining HP for the last partial unit
	var health_remain = remaining_hp % target_card.unit.health

	# Update card properties
	target_card.number = units_remain + int(health_remain > 0)
	
	# If there are no units left, set current_health to 0
	if units_remain == 0 && health_remain == 0:
		target_card.current_health = 0
	else:
		target_card.current_health = health_remain if health_remain > 0 else target_card.unit.health
		
	
func heal(target_card : Card, heal : int, resurrect : bool = true):
	# Calculate total current HP across all units
	var target_overall_hp = (target_card.number - 1) * target_card.unit.health + target_card.current_health
	
	# Calculate maximum possible HP based on resurrection setting
	var max_target_hp = (target_card.max_units if resurrect else target_card.number) * target_card.unit.health
	
	# Apply healing, capped at maximum
	var remaining_hp = min(target_overall_hp + heal, max_target_hp)
	
	# Calculate how many full units we can have
	var units_remain = int(remaining_hp / target_card.unit.health)
	
	# Calculate remaining HP for the last partial unit
	var health_remain = remaining_hp % target_card.unit.health

	# Update card properties
	target_card.number = units_remain + int(health_remain > 0)
	target_card.current_health = health_remain if health_remain > 0 else target_card.unit.health



@rpc("any_peer", "call_local","reliable")
func make_turn(send_id:int, turn_desc : Dictionary): # Format {"action":ActionTaken,"target":int, "?damage":int}
	var recv_id = multiplayer.get_unique_id()
	var action : ActionTaken = turn_desc["action"]
	var target_field : PlayerField = player_field
	var opposite_field : PlayerField = enemy_field
	var invert : bool = true
	if recv_id == send_id:
		reset_visualize_attacker()
		target_field = enemy_field # Called from and on command host
		opposite_field = player_field
		invert = false
	
	var attacker:TurnScale.CardRef = atb_bar.first()
	var att_card = attacker.ref
	for a : Ability in att_card._unit.abilities:
		if a.viz_type == Ability.VizType.PASSIVE:
			a.execute(att_card, self, null)
	
	match action:
		ActionTaken.MOVE:
			var target_slot : int = turn_desc["target"]
			var slot : CardSlot = opposite_field.get_at(target_slot, invert)
			opposite_field.get_at(att_card.slot, false).reset_card()				
			slot.set_card(att_card)
			atb_bar.action()

		ActionTaken.ATTACK: # This is called on enemy turn, so everything is mirrored
			var damage : int = turn_desc["damage"]
			var target_slot : int = turn_desc["target"]
			var target : CardSlot = target_field.get_at(target_slot, invert) # inverted
			var target_card : Card = target.card_ref
			
			
			var prev_attacker_pos = att_card.position
			
			att_card.z_index = CardManager.Z_DRAG
			
			var tween = get_tree().create_tween()
			tween.tween_property(att_card, "position", target_card.position, 0.2)
			var timer = get_tree().create_timer(0.2)
			await timer.timeout
			
			attack_card(att_card, target, damage, recv_id == send_id)
			
			# Use attack modifiers
			for a : Ability in att_card._unit.abilities:
				if a.viz_type == Ability.VizType.TARGET:
					a.execute(att_card, self, target_card)
			
			
			# Check win condition
			if attacker.belongs_to_player: # We may win
				if enemy_field.is_empty():
					end_screen.win()
			else: # We might have lost
				if player_field.is_empty():
					end_screen.loose()
					
			var tween2 = get_tree().create_tween()
			tween2.tween_property(att_card, "position", prev_attacker_pos, 0.3)
			var timer2 = get_tree().create_timer(0.3)
			await timer2.timeout
			
			att_card.z_index = CardManager.Z_NORMAL
			
			atb_bar.action()

		ActionTaken.WAIT:
			atb_bar.wait()
			
		# Reserved
		ActionTaken.ABILITY:
			pass

	# Exec for all
	var new_first : TurnScale.CardRef = atb_bar.first()
	reset_vizualize()
	if new_first.belongs_to_player:
		on_card_turn(new_first.ref)
		wait_button.disabled = false
		wait_button.text = "Wait"
	else:
		attacker_card = null
		wait_button.disabled = true
		wait_button.text = "Opponent's turn..."


func _on_wait_pressed() -> void:
	wait()

func on_enemy_hover(target_card:Card):
	if !attacker_card: return null
	var damage : int = attacker_card.unit.attack * attacker_card.number
	
	var unit = target_card._unit
	var target_overall_hp = (target_card.number - 1) * target_card.unit.health + target_card.current_health
	var remaining_hp = max(target_overall_hp - damage, 0)
	
	var units_remain = remaining_hp / target_card.unit.health
	var health_remain = remaining_hp % target_card.unit.health
	
	return [damage, target_card.number - units_remain - int(health_remain > 0)]

func is_enemy(card:Card):
	return enemy_field.grid[card.slot].card_ref == card

func on_card_hovered_battle(card: Card):
	if !attacker_card: return
	for a : Ability in attacker_card._unit.abilities:
		if a.viz_type == Ability.VizType.TARGET:
			a.visualize(attacker_card, self, card)
			
	if card.card_state == Card.Outline.ENEMY_FULL:
		var dmg_kills : Array = on_enemy_hover(card)
		if dmg_kills:
			var dmg = dmg_kills[0]
			var kills = dmg_kills[1]
			tooltip.label.text = "Damage: {dmg}\nKills: {kills}".format({"dmg": dmg, "kills":kills})
			tooltip.visible = true
			
func on_card_hovered_off_battle(card: Card):
	tooltip.visible = false
	if !attacker_card: return
	for a : Ability in attacker_card._unit.abilities:
		if a.viz_type == Ability.VizType.TARGET:
			a.reset_visualize()

func reset_visualize_attacker():
	if !attacker_card: return
	for a : Ability in attacker_card._unit.abilities:
		a.reset_visualize()

func attack_card(attacker : Card, target : CardSlot, damage : int, local:bool):
	var target_card : Card = target.card_ref
	var before : int = target_card.number
	take_damage(target_card, damage)
	var units_killed = before - target_card.number
	
	if local:
		combat_log.add_combat_event("{unit_a} attacked enemy {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":attacker._unit.tag.to_upper(),
			"unit_t":target.card_ref.unit.tag.to_upper(),
			"dmg":damage,
			"kill":units_killed}))
	else:
		combat_log.add_combat_event("{unit_a} attacked your {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":attacker._unit.tag.to_upper(),
			"unit_t":target.card_ref.unit.tag.to_upper(),
			"dmg":damage,
			"kill":units_killed}))
	
	if target_card.number == 0: # Remove
		atb_bar.trim_card(target_card)
		target.reset_card()
		target_card.queue_free()

func heal_card(attacker : Card, target : CardSlot, damage : int, local:bool):
	var target_card : Card = target.card_ref
	var before : int = target_card.number
	heal(target_card, damage)
	var units_killed = target_card.number - before
	
	if local:
		combat_log.add_combat_event("{unit_a} healed enemy {unit_t} for {dmg}, resurrected {kill}"
			.format({"unit_a":attacker._unit.tag.to_upper(),
			"unit_t":target.card_ref.unit.tag.to_upper(),
			"dmg":damage,
			"kill":units_killed}))
	else:
		combat_log.add_combat_event("{unit_a} healed your {unit_t} for {dmg}, resurrected {kill}"
			.format({"unit_a":attacker._unit.tag.to_upper(),
			"unit_t":target.card_ref.unit.tag.to_upper(),
			"dmg":damage,
			"kill":units_killed}))
