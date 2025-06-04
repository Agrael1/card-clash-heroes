class_name CardViewATB
extends Control

const SELF_SCENE = preload("res://objects/card_view_atb.tscn")

@onready var card_scene : Card = $Card
@onready var current_time_label : RichTextLabel = $CurrentTime

var _card_ref : TurnScale.CardRef = null
var card_ref : TurnScale.CardRef :
	set(value):
		if(card_scene):
			if !value: return
			if _card_ref: 
				_card_ref.ref.on_count_changed.disconnect(_on_count_changed)
				_card_ref.current_time_changed.disconnect(_on_current_time_changed)
				
			value.ref.on_count_changed.connect(_on_count_changed)
			value.current_time_changed.connect(_on_current_time_changed)
			
			card_scene.collision_mask = value.ref.collision_mask
			card_scene.unit = value.ref.unit
			card_scene.number = value.ref.number
			card_scene.sprite.modulate = Color.SKY_BLUE if value.belongs_to_player else Color.INDIAN_RED
			current_time = value.current_time
			
		_card_ref = value
	get:
		return _card_ref
		
var _current_time : float
var current_time : float :
	set(value):
		if current_time_label:
			current_time_label.text = "%.2f" % value
		_current_time = value
	get:
		return _current_time


func _set_values():
	var xcard_ref = _card_ref
	_card_ref = null
	card_ref = xcard_ref
	
	current_time = _current_time

func _ready() -> void:
	_set_values()

# Bindings
func _on_count_changed(new_count : int):
	card_scene.number = new_count

func _on_current_time_changed(new_time : float):
	current_time = new_time
