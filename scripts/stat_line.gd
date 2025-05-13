class_name StatLine
extends Control

@onready var ui_stat_name : RichTextLabel = $HBoxContainer/StatName
@onready var ui_stat_value : RichTextLabel = $HBoxContainer/StatProfile

var _stat_name : String
var stat_name : String:
	set(value):
		_stat_name = value
		if ui_stat_name:
			ui_stat_name.text = value
	get:
		return _stat_name

var _stat_val : String
var stat_val : String:
	set(value):
		_stat_val = value
		if ui_stat_name:
			ui_stat_value.text = value
	get:
		return _stat_val

func _ready() -> void:
	stat_name = _stat_name
	stat_val = _stat_val
	
