class_name Card
extends Node

const SELF_SCENE = preload("res://objects/card.tscn")

signal mouse_enter
signal mouse_exit
signal mouse_click(card : Card)

enum Outline {NONE, CURRENT, ENEMY_FULL, ENEMY_PENALTY}

# Prooperties
var _collision_mask : int = 0
@export var collision_mask : int = 0 :
	set(value):
		_collision_mask = value
		if(area):
			area.collision_mask = 1 << value
			area.collision_layer = 1 << value
	get:
		return _collision_mask

var _number:int = 0
@export var number : int :
	set(value):
		_number = value
		if number_panel:
			number_panel.set_number(_number)
	get:
		return _number;
		
var _unit:Unit = null
@export var unit:Unit:
	set(value):
		_unit = value
		if sprite:
			sprite.texture = _unit.sprite
	get:
		return _unit

var card_state: Outline = Outline.NONE
var current_health

var slot:int = -1
@onready var number_panel = $Panel
@onready var sprite = $Sprite2D
@onready var area :Area2D = $Area2D
@onready var outline:StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	area.collision_mask = 1 << collision_mask
	area.collision_layer = 1 << collision_mask
	outline.bg_color = Color.TRANSPARENT
	outline.set_expand_margin_all(2)
	$Outline.add_theme_stylebox_override("panel", outline)
	
	number_panel.number = _number
	sprite.texture = unit.sprite
	current_health = unit.health
	
	var parent = get_parent()
	if parent is CardManager:
		parent.connect_card(self)


func _on_area_2d_mouse_entered() -> void:
	emit_signal("mouse_enter", self) # pass the card

func _on_area_2d_mouse_exited() -> void:
	emit_signal("mouse_exit", self)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		emit_signal("mouse_click", self)
		
func export():
	return { "unit": unit.tag, "number" : _number, "slot" : slot }

func set_outline(xoutline : Outline):
	card_state = xoutline
	match xoutline:
		Outline.CURRENT:
			outline.bg_color = Color.YELLOW
		Outline.ENEMY_FULL:
			outline.bg_color = Color.RED
		Outline.ENEMY_PENALTY:
			outline.bg_color = Color.ORANGE
		_:
			outline.bg_color = Color.TRANSPARENT
