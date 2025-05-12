class_name RaceSelect
extends Control

var card_db_ref : CardDB = preload("res://resources/card_db.tres")
var races : Array[String]

var _index : int
var index : int:
	set(value):
		_index = value
		if line_edit:
			line_edit.text = races[_index]
	get:
		return _index

@onready var line_edit : LineEdit = $HBoxContainer/LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	races = card_db_ref.races.keys()
	races.append("Random")
	index = races.size() - 1


func _on_back_pressed() -> void:
	index = (index - 1) % races.size()


func _on_forth_pressed() -> void:
	index = (index + 1) % races.size()

func pick_race() -> String:
	if index == races.size() - 1:
		return races.slice(0, races.size() - 1).pick_random()
	return races[index]
