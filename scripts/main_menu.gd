class_name MainMenu
extends Control

var main_scene : PackedScene = preload("res://scenes/main.tscn")

@onready var host : Button = $MenuContainer/MarginContainer/VBoxContainer/Host
@onready var join : Button = $MenuContainer/MarginContainer/VBoxContainer/Join
@onready var exit : Button = $MenuContainer/MarginContainer/VBoxContainer/Exit
@onready var menu : Control = $MenuContainer

@export var port : int = 123
@export var address : String = "localhost"

var peer = ENetMultiplayerPeer.new()

func load_main_scene() -> void:
	menu.visible = false
	add_child(main_scene.instantiate())

func _on_join_pressed() -> void:
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	load_main_scene()

func _on_host_pressed() -> void:
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(on_peer_connected)
	load_main_scene()

func _on_exit_pressed() -> void:
	get_tree().quit()

func on_peer_connected(peer_id:int)->void:
	print("successfuly connected")
