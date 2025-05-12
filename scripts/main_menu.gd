class_name MainMenu
extends Control

var main_scene : PackedScene = preload("res://scenes/main.tscn")

@onready var menu : Control = $MenuContainer

@onready var host_submenu : Control = $MenuContainer/MarginContainer/HostSubmenu
@onready var join_submenu : Control = $MenuContainer/MarginContainer/JoinSubmenu
@onready var main_submenu : Control = $MenuContainer/MarginContainer/MainSubmenu

@onready var host_oid : TextEdit = $MenuContainer/MarginContainer/HostSubmenu/HBoxContainer/TextEdit
@onready var join_oid : LineEdit = $MenuContainer/MarginContainer/JoinSubmenu/LineEdit

@onready var port_box : RichTextLabel = $MenuContainer/MarginContainer/HostSubmenu/VBoxContainer/HBoxContainer/RichTextLabel
var race_box : RaceSelect

var main_scene_instance : Main

func _ready() -> void:
	await Multiplayer.noray_connected
	host_oid.text = Noray.oid
	port_box.text = "Port: " + str(Noray.local_port)

func load_main_scene(is_host:bool = false) -> void:
	menu.visible = false
	var xscene : Main = main_scene.instantiate()
	xscene.race = race_box.pick_race()
	
	add_child(xscene)
	main_scene_instance = xscene

func _on_join_pressed() -> void:
	main_submenu.visible = false
	join_submenu.visible = true
	race_box = $MenuContainer/MarginContainer/JoinSubmenu/RaceSelect

func _on_host_pressed() -> void:
	Multiplayer.host()
	main_submenu.visible = false
	host_submenu.visible = true
	race_box = $MenuContainer/MarginContainer/HostSubmenu/RaceSelect
	multiplayer.peer_connected.connect(
		func(peer_id:int): load_main_scene()
	)


func _on_exit_pressed() -> void:
	get_tree().quit()

func load_main_menu():
	menu.visible = true
	main_scene_instance.queue_free()

func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)

func _on_join_oid_pressed() -> void:
	if Multiplayer.join(join_oid.text):
		multiplayer.connected_to_server.connect(
			load_main_scene
		)

func _on_host_back_pressed() -> void:
	main_submenu.visible = true
	host_submenu.visible = false
	Multiplayer.unhost()

func _on_join_back_pressed() -> void:
	main_submenu.visible = true
	join_submenu.visible = false

func _on_text_edit_text_submitted(new_text: String) -> void:
	if Multiplayer.join(new_text):
		multiplayer.connected_to_server.connect(
			load_main_scene
		)

func _on_copy_port_pressed() -> void:
	DisplayServer.clipboard_set(":"+str(Noray.local_port))
