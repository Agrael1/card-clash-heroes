class_name Card
extends Control

const SELF_SCENE = preload("res://objects/card.tscn")
const SELECTED_Z_IDX_JUMP := 2
const HOVERED_SCALE := 1.2

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
var max_units : int

var scale_tween: Tween
var sprite_base_scale: Vector2

var slot:int = -1
@onready var number_panel = $Panel
@onready var sprite = $Sprite2D
@onready var area :Area2D = $Area2D
@onready var pointer : Sprite2D = $Triangle
@onready var outline:StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	sprite_base_scale = sprite.scale
	sprite.scale = Vector2(0.0, 0.0)
	tween_scale(1.0, 0.4, Tween.TRANS_ELASTIC)
	area.collision_mask = 1 << collision_mask
	area.collision_layer = 1 << collision_mask
	outline.bg_color = Color.TRANSPARENT
	outline.set_expand_margin_all(6)
	$Outline.add_theme_stylebox_override("panel", outline)
	
	number_panel.number = _number
	sprite.texture = unit.sprite
	current_health = unit.health
	
	var parent = get_parent()
	if parent is CardManager:
		parent.connect_card(self)

func tween_scale(new_scale_percent: float, time := 0.1, trans := Tween.TRANS_LINEAR) -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween.stop()
		scale_tween.kill()
	scale_tween = get_tree().create_tween()
	scale_tween.tween_property(sprite, "scale", sprite_base_scale * new_scale_percent, time).set_trans(trans)

func _on_area_2d_mouse_entered() -> void:
	tween_scale(HOVERED_SCALE)
	z_index += SELECTED_Z_IDX_JUMP
	mouse_enter.emit(self) # pass the card

func _on_area_2d_mouse_exited() -> void:
	tween_scale(1.0)
	z_index -= SELECTED_Z_IDX_JUMP
	mouse_exit.emit(self)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		mouse_click.emit(self)
		
func export():
	return { "unit": unit.tag, "number" : _number, "slot" : slot }

func set_outline(xoutline : Outline):
	card_state = xoutline
	match xoutline:
		Outline.CURRENT:
			outline.bg_color = Color.FOREST_GREEN
		Outline.ENEMY_FULL:
			outline.bg_color = Color.RED
		Outline.ENEMY_PENALTY:
			outline.bg_color = Color.ORANGE
		_:
			outline.bg_color = Color.TRANSPARENT
