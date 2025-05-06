class_name MainMenu
extends Control

var main_scene : PackedScene = preload("res://scenes/main.tscn")

@onready var host : Button = $MenuContainer/MarginContainer/VBoxContainer/Host
@onready var join : Button = $MenuContainer/MarginContainer/VBoxContainer/Join
@onready var exit : Button = $MenuContainer/MarginContainer/VBoxContainer/Exit
@onready var menu : Control = $MenuContainer

@export var port : int = 1234
@export var address : String = "localhost"

var peer = ENetMultiplayerPeer.new()

func load_main_scene(is_host:bool = false) -> void:
	menu.visible = false
	var xscene : Main = main_scene.instantiate()
	if is_host:
		multiplayer.peer_connected.connect(xscene.on_peer_connected)
		multiplayer.peer_disconnected.connect(xscene.on_peer_disconnected)
	add_child(xscene)

func _on_join_pressed() -> void:
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	load_main_scene()

func _on_host_pressed() -> void:
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
	load_main_scene(true)

func _on_exit_pressed() -> void:
	get_tree().quit()
