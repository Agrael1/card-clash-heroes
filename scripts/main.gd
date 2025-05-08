class_name Main
extends PanelContainer

signal player_ready_changed(peer_id, is_ready)
signal both_players_ready

var local_player_ready = false
var remote_player_ready = false
var remote_player_id = 0

@onready var main_menu : MainMenu = $"../"
@onready var ready_button : Button = $MarginContainer3/Attack
@onready var enemy_field : PlayerField = $MarginContainer2/EnemyField
@onready var player_field : PlayerField = $MarginContainer/PlayerField
@onready var shop : Shop = $Shop
@onready var turn_scale : TurnScale = $TurnScale
@onready var card_manager : CardManager = $CardManager
@onready var battle_field : BattleField = $BattleField



func on_peer_connected(peer_id:int)->void:
	print("successfuly connected")
	
func on_peer_disconnected(peer_id:int)->void:
	print("disconnected")
	
func on_local_ready_changed()->void:
	shop.visible = !local_player_ready
	card_manager.block_free_move = local_player_ready
	
func on_both_ready()->void:
	sync_fields.rpc(multiplayer.get_unique_id(), player_field.export())
	turn_scale.visible = true
	turn_scale.populate_atb_bar()
	
	# on host calculate the turns


func _on_attack_pressed() -> void:
	var is_ready : bool = toggle_ready()
	ready_button.text = "Cancel Ready" if is_ready else "Ready"



func check_both_ready():
	if local_player_ready && remote_player_ready && remote_player_id != 0:
		ready_button.disabled = true
		ready_button.visible = false
		on_both_ready()
		return true
	return false
	
func toggle_ready():
	local_player_ready = !local_player_ready
	# Notify the other player about our ready status
	update_ready_status.rpc(local_player_ready, multiplayer.get_unique_id())
	# Check if both players are ready
	check_both_ready()
	on_local_ready_changed()
	return local_player_ready

# RPC to update a player's ready status
@rpc("any_peer", "call_local", "reliable")
func update_ready_status(is_ready:bool, unique_id:int):
	var sender_id : int = multiplayer.get_unique_id()
	if sender_id == unique_id: # Local call
		player_ready_changed.emit(multiplayer.get_unique_id(), is_ready)
	else:
		remote_player_ready = is_ready
		remote_player_id = sender_id
		player_ready_changed.emit(sender_id, is_ready)
		
		check_both_ready()
	
@rpc("any_peer", "call_local", "reliable")
func sync_fields(unique_id:int, field_data):
	var sender_id : int = multiplayer.get_unique_id()
	if unique_id != sender_id:
		enemy_field.import(field_data)
		if unique_id != 1:
			start_battle()

func start_battle():
	#find first card on host (test)
	var index : int = player_field.grid.find_custom(func(x:CardSlot):return !x.is_empty())
	if index!=-1:
		var card : Card = player_field.grid[index].card_ref
		battle_field.on_card_turn(card)
