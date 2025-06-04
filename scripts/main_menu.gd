class_name MainMenu
extends Control

signal sync_from_host

var main_scene : PackedScene = preload("res://scenes/main.tscn")

@onready var menu : Control = $MenuContainer

@onready var host_submenu : Control = $MenuContainer/MarginContainer/HostSubmenu
@onready var join_submenu : Control = $MenuContainer/MarginContainer/JoinSubmenu
@onready var main_submenu : Control = $MenuContainer/MarginContainer/MainSubmenu
@onready var settings_submenu : Control = $MenuContainer/MarginContainer/SettingsSubmenu


@onready var host_oid : TextEdit = $MenuContainer/MarginContainer/HostSubmenu/HBoxContainer/TextEdit
@onready var join_oid : LineEdit = $MenuContainer/MarginContainer/JoinSubmenu/LineEdit

@onready var main_bg_texture_rect: TextureRect = $MainBGTextureRect
@onready var join_bg_texture_rect: TextureRect = $JoinBGTextureRect
@onready var host_bg_texture_rect: TextureRect = $HostBGTextureRect
@onready var battle_bg_texture_rect: TextureRect = $BattleBGTextureRect

@onready var port_box : RichTextLabel = $MenuContainer/MarginContainer/HostSubmenu/VBoxContainer/HBoxContainer/RichTextLabel
@onready var gold_box : RaceSelect = $MenuContainer/MarginContainer/HostSubmenu/RaceSelect2
var race_box : RaceSelect
var gold : int = 50

var main_scene_instance : Main

func _ready() -> void:
	await Multiplayer.noray_connected
	host_oid.text = Noray.oid
	port_box.text = "Port: " + str(Noray.local_port)
	multiplayer.peer_disconnected.connect(
		func(_z): load_main_menu()
	)

func load_main_scene() -> void:
	menu.visible = false
	battle_bg_texture_rect.visible = true
	host_bg_texture_rect.visible = false
	join_bg_texture_rect.visible = false
	var xscene : Main = main_scene.instantiate()
	xscene.race = race_box.pick_race()
	
	add_child(xscene)
	xscene.shop.gold = gold
	main_scene_instance = xscene

func _on_join_pressed() -> void:
	main_submenu.visible = false
	main_bg_texture_rect.visible = false
	join_bg_texture_rect.visible = true
	join_submenu.visible = true
	race_box = $MenuContainer/MarginContainer/JoinSubmenu/RaceSelect

func host_connect(_peer_id:int):
	var gvalue = gold_box.pick_race()
	if gvalue == gold_box.races[0]:
		gold = 500
	elif gvalue == gold_box.races[1]:
		gold = 1000
	elif gvalue == gold_box.races[2]:
		gold = 1500
	sync_gold.rpc(gold)
	
	load_main_scene()

func join_connect():
	await sync_from_host
	load_main_scene()

func _on_host_pressed() -> void:
	Multiplayer.host()
	main_bg_texture_rect.visible = false
	host_bg_texture_rect.visible = true
	main_submenu.visible = false
	host_submenu.visible = true
	race_box = $MenuContainer/MarginContainer/HostSubmenu/RaceSelect
	multiplayer.peer_connected.connect(
		host_connect
	)

# Called only from host to peer
@rpc("call_remote", "reliable")
func sync_gold(in_gold:int):
	gold = in_gold
	sync_from_host.emit()

func _on_exit_pressed() -> void:
	get_tree().quit()

func load_main_menu():
	menu.visible = true
	main_bg_texture_rect.visible = false
	host_bg_texture_rect.visible = false
	join_bg_texture_rect.visible = false
	battle_bg_texture_rect.visible = false
	multiplayer.multiplayer_peer.close()
	
	host_submenu.visible = false
	join_submenu.visible = false
	main_submenu.visible = true
	main_bg_texture_rect.visible = true
	main_scene_instance.queue_free()
	

func _on_copy_oid_pressed() -> void:
	DisplayServer.clipboard_set(Noray.oid)

func _on_host_back_pressed() -> void:
	main_submenu.visible = true
	host_submenu.visible = false
	main_bg_texture_rect.visible = true
	host_bg_texture_rect.visible = false
	Multiplayer.unhost()
	multiplayer.peer_connected.disconnect(
		host_connect
	)
	

func _on_join_back_pressed() -> void:
	main_submenu.visible = true
	join_submenu.visible = false
	main_bg_texture_rect.visible = true
	join_bg_texture_rect.visible = false
	multiplayer.connected_to_server.disconnect(join_connect)

func _on_join_oid_pressed() -> void:
	if Multiplayer.join(join_oid.text):
		multiplayer.connected_to_server.connect(
			join_connect
		)

func _on_text_edit_text_submitted(new_text: String) -> void:
	if Multiplayer.join(new_text):
		multiplayer.connected_to_server.connect(
			join_connect
		)

func _on_copy_port_pressed() -> void:
	DisplayServer.clipboard_set(":"+str(Noray.local_port))

func _on_settings_pressed() -> void:
	main_submenu.visible = false
	settings_submenu.visible = true

func _on_settings_back_pressed() -> void:
	main_submenu.visible = true
	settings_submenu.visible = false
