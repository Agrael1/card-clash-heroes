class_name GameOver
extends Control

@export var animation_player: AnimationPlayer
@onready var label : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel

func _ready() -> void:
	close()

func open():
	visible = true
	animation_player.play(&"blur")

func win():
	label.text = "You Won!"
	label.modulate = Color.GREEN_YELLOW
	open()
	
func loose():
	label.text = "You Lost!"
	label.modulate = Color.INDIAN_RED
	open()

func close():
	animation_player.play(&"RESET")
	visible = false


func _on_main_menu_pressed() -> void:
	close()
	var main_menu:MainMenu = find_parent("Main")
	main_menu.load_main_menu()

func _on_quit_pressed() -> void:
	close()
	get_tree().quit()
