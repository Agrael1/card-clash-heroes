class_name MainMenu
extends Control

var main_scene : PackedScene = preload("res://scenes/main.tscn")

@onready var menu : Control = $MenuContainer

@onready var host_submenu : Control = $MenuContainer/MarginContainer/HostSubmenu
@onready var join_submenu : Control = $MenuContainer/MarginContainer/JoinSubmenu
@onready var main_submenu : Control = $MenuContainer/MarginContainer/MainSubmenu

@onready var host_oid : TextEdit = $MenuContainer/MarginContainer/HostSubmenu/HBoxContainer/TextEdit
@onready var join_oid : TextEdit = $MenuContainer/MarginContainer/JoinSubmenu/TextEdit

@export var port : int = 1234
@export var address : String = "localhost"

var peer = ENetMultiplayerPeer.new()
var main_scene_instance : Main

func _ready() -> void:
	await Multiplayer.noray_connected
	host_oid.text = Noray.oid


func load_main_scene(is_host:bool = false) -> void:
	menu.visible = false
	var xscene : Main = main_scene.instantiate()
	if is_host:
		multiplayer.peer_connected.connect(xscene.on_peer_connected)
		multiplayer.peer_disconnected.connect(xscene.on_peer_disconnected)
	add_child(xscene)
	main_scene_instance = xscene

func _on_join_pressed() -> void:
	main_submenu.visible = false
	join_submenu.visible = true

func _on_host_pressed() -> void:
	Multiplayer.host()
	main_submenu.visible = false
	host_submenu.visible = true

	
func _on_start_pressed()-> void:
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
	load_main_scene(true)

func _on_exit_pressed() -> void:
	get_tree().quit()

func load_main_menu():
	menu.visible = true
	main_scene_instance.queue_free()


func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)


func _on_join_oid_pressed() -> void:
	Multiplayer.join(join_oid.text)
	#load_main_scene()
