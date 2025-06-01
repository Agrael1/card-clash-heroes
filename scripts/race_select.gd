class_name RaceSelect
extends Control

var card_db_ref : CardDB = preload("res://resources/card_db.tres")
@export var races : Array[String]
var custom : bool = false

var _index : int = 0
@export var index : int:
	set(value):
		_index = value
		if line_edit && !races.is_empty():
			line_edit.text = races[_index]
	get:
		return _index

@onready var line_edit : LineEdit = $HBoxContainer/LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	index = _index
	custom = !races.is_empty()
	if !custom:
		races = card_db_ref.races.keys()
		races.append("Random")
		index = races.size() - 1


func _on_back_pressed() -> void:
	index = (index - 1) % races.size()


func _on_forth_pressed() -> void:
	index = (index + 1) % races.size()

func pick_race() -> String:
	if !custom:
		if index == races.size() - 1:
			return races.slice(0, races.size() - 1).pick_random()
	return races[index]
