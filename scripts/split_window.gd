class_name SplitDialog
extends Control

@onready var left_card = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/Card
@onready var right_card = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Card

@onready var left_num : LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/LeftEdit
@onready var right_num : LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/RightEdit
@onready var slider : HSlider = $MarginContainer/Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HSlider

var original_left = 0
var original_right = 0
var original_sum = 0

var text_left : String
var text_right : String

signal card_split_succeded(left, right)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func open_for(card : Card):
	left_card.unit = card.unit
	right_card.unit = card.unit
	visible = true
	original_sum = card.number
	original_left = card.number
	var l = original_left / 2
	var r = original_left - l
	
	text_left = str(l)
	left_num.text = text_left
	text_right = str(r)
	right_num.text = text_right
	slider.max_value = original_sum
	slider.min_value = 0
	slider.value = l
	
	
func _on_split_pressed() -> void:
	visible = false
	card_split_succeded.emit(left_num.text.to_int(), right_num.text.to_int())

func _on_cancel_pressed() -> void:
	visible = false
	card_split_succeded.emit(original_left, original_right)

func _on_h_slider_value_changed(value: float) -> void:
	var i = int(value)
	left_num.text = str(i)
	right_num.text = str(original_sum - i)



func _on_left_edit_text_changed(new_text: String) -> void:
	if !new_text.is_valid_int():
		left_num.text = text_left
		return
	
	var l = new_text.to_int()
	var r = original_sum - l
	
	if r < 0:
		left_num.text = text_left
		return
	
	text_left = new_text
	text_right = str(r)
	left_num.text = text_left
	right_num.text = text_right
	


func _on_right_edit_text_changed(new_text: String) -> void:
	if !new_text.is_valid_int():
		right_num.text = text_right
		return
		
	var r = new_text.to_int()
	var l = original_sum - r
	
	if l < 0:
		right_num.text = text_right
		return
	
	text_right = new_text
	text_left = str(l)
	left_num.text = text_left
	right_num.text = text_right
