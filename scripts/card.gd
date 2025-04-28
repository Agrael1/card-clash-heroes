class_name Card
extends Node

signal mouse_enter
signal mouse_exit

@export var collision_mask : int = 0

func _ready() -> void:
	var area :Area2D = $Area2D
	area.collision_mask = 1 << collision_mask
	area.collision_layer = 1 << collision_mask
	
	var parent = get_parent()
	if parent is CardManager:
		parent.connect_card(self)


func _on_area_2d_mouse_entered() -> void:
	emit_signal("mouse_enter", self) # pass the card


func _on_area_2d_mouse_exited() -> void:
	emit_signal("mouse_exit", self)
