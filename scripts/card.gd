class_name Card
extends Control

enum CardSelection {NONE, CURRENT, ENEMY_FULL, ENEMY_PENALTY, HEAL}

const SELF_SCENE := preload("res://objects/card.tscn")
const HOVERED_SCALE := 1.1

#region signals
signal mouse_enter(card : Card)
signal mouse_exit(card : Card)
signal mouse_click(card : Card, mouse_button : int)
#endregion

#region imports
@onready var number_panel : Panel = $Panel
@onready var sprite : Sprite2D = $Sprite2D
@onready var area : Area2D = $Area2D
@onready var pointer : Sprite2D = $Triangle
@onready var outline : StyleBoxFlat = StyleBoxFlat.new()
#endregion

#region properties
var _collision_mask : int = 0
@export var collision_mask : int :
	set(value):
		_collision_mask = value
		if(area):
			area.collision_mask = 1 << value
			area.collision_layer = 1 << value
	get:
		return _collision_mask

var _number : int = 0
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

var _card_state := CardSelection.NONE
@export var card_state:CardSelection:
	set(value):
		_card_state = value
		if !outline: return
		match value:
			CardSelection.CURRENT, CardSelection.HEAL:
				outline.bg_color = Color.FOREST_GREEN
			CardSelection.ENEMY_FULL:
				outline.bg_color = Color.RED
			CardSelection.ENEMY_PENALTY:
				outline.bg_color = Color.ORANGE
			_:
				outline.bg_color = Color.TRANSPARENT
		pointer.visible = value == CardSelection.CURRENT
	get:
		return _card_state
#endregion


var current_health : int
var max_units : int
var scale_tween: Tween
var base_scale: Vector2
var wiggling_time := -1.0
var slot:int = -1


#region private
func _set_ready_props() -> void:
	collision_mask = _collision_mask
	unit = _unit
	card_state = _card_state
	number = _number

func _ready() -> void:
	_set_ready_props()
	current_health = unit.health
	
	# Make it appear
	base_scale = self.scale
	self.scale = Vector2(0,0)
	tween_scale(1.0, 0.4, Tween.TRANS_ELASTIC)
	
	outline.set_expand_margin_all(6)
	$Outline.add_theme_stylebox_override("panel", outline)
	
	var parent = get_parent()
	if parent is CardManager:
		parent.connect_card(self)

func _process(delta: float) -> void:
	if wiggling_time >= 0:
		wiggling_time += delta
		self.rotation = cos(wiggling_time * 4) * 0.1
		self.scale = base_scale * (1.0 + ((1.0 + sin(wiggling_time * 4)) / 10.0))
#endregion


func drag_began() -> void:
	wiggling_time = 0

func drag_ended() -> void:
	wiggling_time = -1
	self.rotation = 0
	self.scale = base_scale * HOVERED_SCALE

func tween_scale(new_scale_percent: float, time := 0.1, trans := Tween.TRANS_LINEAR) -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween.stop()
		scale_tween.kill()
	scale_tween = get_tree().create_tween()
	scale_tween.tween_property(self, "scale", base_scale * new_scale_percent, time).set_trans(trans)

# returns [a, b, c] where a is new number of card and b is new current health, c is oveall heal
func calc_heal(heal : int, resurrect : bool = true) -> Array:
	var target_overall_hp = (number - 1) * unit.health + current_health
	var max_target_hp = (max_units if resurrect else number) * unit.health
	
	# Apply healing, capped at maximum
	var remaining_hp = min(target_overall_hp + heal, max_target_hp)
	var units_remain = int(remaining_hp / unit.health)
	
	# Calculate remaining HP for the last partial unit
	var health_remain = remaining_hp % unit.health

	# Update card properties
	var new_number = units_remain + int(health_remain > 0)
	var new_current_health = health_remain if health_remain > 0 else unit.health
	return [new_number, new_current_health, remaining_hp - target_overall_hp]

# returns [a, b, c] where a is new number of card and b is new current health, c is oveall heal
func set_heal(heal : int, resurrect : bool = true) -> Array:
	var heal_result := calc_heal(heal, resurrect)

	# Update card properties
	number = heal_result[0]
	current_health = heal_result[1]
	return heal_result

#region private slots
func _on_area_2d_mouse_entered() -> void:
	tween_scale(HOVERED_SCALE)
	mouse_enter.emit(self) # pass the card

func _on_area_2d_mouse_exited() -> void:
	tween_scale(1.0)
	mouse_exit.emit(self)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.is_pressed():
		mouse_click.emit(self, event.button_index)
#endregion
		
func export():
	return { "unit": unit.tag, "number" : _number, "slot" : slot }
