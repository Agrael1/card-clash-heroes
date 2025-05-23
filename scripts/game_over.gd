class_name GameOver
extends Control

@export var animation_player: AnimationPlayer
@onready var label : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/RichTextLabel
var endgame = false

func _ready() -> void:
	close()

func open():
	visible = true
	animation_player.play(&"blur")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if endgame:
			_on_main_menu_pressed()
		elif visible:
			_resume()
		else:
			_pause()
			

func win():
	endgame = true
	label.text = "You Won!"
	label.modulate = Color.GREEN_YELLOW
	open()
	
func loose():
	endgame = true
	label.text = "You Lost!"
	label.modulate = Color.INDIAN_RED
	open()

func close():
	animation_player.play(&"RESET")
	visible = false

func _pause() -> void:
	label.text = "Pause"
	label.modulate = Color.WHITE
	visible = true
	animation_player.play(&"blur")
	
func _resume() -> void:
	animation_player.play_backwards(&"blur")
	visible = false

func _on_main_menu_pressed() -> void:
	close()
	var main_menu:MainMenu = find_parent("Main")
	main_menu.load_main_menu()

func _on_quit_pressed() -> void:
	close()
	get_tree().quit()
