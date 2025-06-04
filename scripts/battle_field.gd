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
@onready var rain : Rain = $"../Rain"
@onready var forecast : Forecast = $Weather

var turn_num = 0
var attacker_card : Card
var current_weather : Weather

func _process(_delta: float) -> void:
	if tooltip.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip.position = mouse_pos + Vector2(10, 10) 

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				tooltip.visible = false

func on_new_turn_host():
	turn_num += 1
	if turn_num % 5 == 0:
		var pick_rand = randf()
		sync_weather.rpc(pick_rand>=0.5)

func on_card_turn(card:Card):
	# first color the selected card
	card.card_state = Card.CardSelection.CURRENT
	wait_button.disabled = false
	wait_button.focus_mode = Control.FOCUS_NONE
	wait_button.text = "Wait"
	
	attacker_card = card	
	
	# Visualize passive abilities
	if !attacker_card: return
	for a : Ability in attacker_card.abilities:
		if a.viz_type == Ability.VizType.PASSIVE:
			a.visualize(attacker_card, null, self)


func try_attack_at(slot_idx:int)->bool:
	if !attacker_card: return false
	
	var card = enemy_field.grid[slot_idx].card_ref
	if card:
		var ability_out : Array[Dictionary] = []
		
		var target_abilities = attacker_card.abilities.filter(func(x):return x.ability_type == Ability.AbilityType.TARGET)
		var validate_target = false
		for i in range(0, target_abilities.size()):
			var ta : Ability = target_abilities[i]
			var valid = ta.validate(attacker_card, card, self)
			validate_target = validate_target || valid
			
			if valid:
				var result = ta.predict(attacker_card, card, self)
				ability_out.append({"index":i, "result":result})
				
		# Only execute if some ability proc
		if !validate_target:return false
		
		make_turn.rpc(multiplayer.get_unique_id(), 
		{	
			"action" : ActionTaken.ATTACK,
			"target" : card.slot,
			"result" : ability_out
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

@rpc("any_peer", "call_local","reliable")
func make_turn(send_id:int, turn_desc : Dictionary): # Format {"action":ActionTaken,"target":int, "?damage":int}
	var recv_id = multiplayer.get_unique_id()
	var action : ActionTaken = turn_desc["action"]
	var target_field : PlayerField = player_field
	var opposite_field : PlayerField = enemy_field
	var invert : bool = true
	
	var attacker : TurnScale.CardRef = atb_bar.first()
	var att_card = attacker.ref
	
	if recv_id == send_id:
		# reset viz
		for a : Ability in att_card.abilities:
			a.reset_visualize()
		att_card.card_state = Card.CardSelection.NONE # Reset arrow above head

		target_field = enemy_field # Called from and on command host
		opposite_field = player_field
		invert = false
		
	# Activate passive abilities
	for passive : Ability in att_card.abilities.filter(func(x):
			return x.ability_type == Ability.AbilityType.PASSIVE && x.validate(att_card, null, self)):
		await passive.apply(att_card, null, self, {})
	
	# Make Weather effect
	if current_weather != null:
		rain.apply(self, {})
	else:
		rain.revert(self)
			
	match action:
		ActionTaken.MOVE:
			var target_slot : int = turn_desc["target"]
			var slot : CardSlot = opposite_field.get_at(target_slot)
			opposite_field.get_at(att_card.slot).reset_card()				
			slot.set_card(att_card)
			atb_bar.action()

		ActionTaken.ATTACK:
			var target_slot : int = turn_desc["target"]
			var result : Array[Dictionary] = turn_desc["result"]
			var target : CardSlot = target_field.get_at(target_slot)
			
			for r: Dictionary in result:
				var index : int = r["index"] # Ability idx
				var ab_result : Dictionary = r["result"]
				var ability : Ability = att_card.abilities[index]
				await ability.apply(att_card, target.card_ref, self, ab_result)
				
			

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
			
		# Reserved
		ActionTaken.ABILITY:
			pass

	# Exec for all
	var new_first : TurnScale.CardRef = atb_bar.first()
	if new_first.belongs_to_player:
		on_card_turn(new_first.ref)
		wait_button.disabled = false
		wait_button.text = "Wait"
	else:
		attacker_card = null
		wait_button.disabled = true
		wait_button.text = "Opponent's turn..."
	
	if (recv_id == 1):
		on_new_turn_host()

@rpc("any_peer", "call_local", "reliable")
func sync_weather(weather):
	if weather:
		rain.visualize(self)
		current_weather = rain
	else:
		current_weather = null
		rain.reset_visualize(self)

func get_opponent_field_for(card:Card)->PlayerField:
	if card.is_enemy():
		return player_field
	else:
		return enemy_field
		
func get_field_of(card:Card)->PlayerField:
	if !card.is_enemy():
		return player_field
	else:
		return enemy_field


#region public slots
func on_card_hovered_battle(card: Card):
	if !attacker_card: return
	for a : Ability in attacker_card.abilities.filter(func(x):return x.viz_type == Ability.VizType.TARGET):
		a.visualize(attacker_card, card, self)
	
	var damage : int = attacker_card.unit.attack * attacker_card.number
	if card.is_enemy() &&\
	 (card.card_state == Card.CardSelection.ENEMY_FULL ||\
	 card.card_state == Card.CardSelection.ENEMY_PENALTY):
		var calc_dmg : Array = card.calc_damage(damage)
		tooltip.label.text = "Damage: {dmg}\nKills: {kills}"\
		.format({"dmg": calc_dmg[2], "kills": card.number - calc_dmg[0]})
		tooltip.visible = true


func on_card_hovered_off_battle(_card: Card):
	tooltip.visible = false
	if !attacker_card: return
	for a : Ability in attacker_card.abilities.filter(func(x):return x.viz_type == Ability.VizType.TARGET):
		a.reset_visualize()
#endregion



func _on_wait_pressed() -> void:
	wait()
