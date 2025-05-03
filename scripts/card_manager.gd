class_name CardManager
extends Node2D

const SLOT_MASK = 1 << 1

var dragged_card : Card
var card_hovered : Card
var screen_size : Vector2

@onready var player_field: PlayerField = $"../MarginContainer/PlayerField"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if dragged_card:
		var mouse_pos = get_global_mouse_position()
		dragged_card.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
		
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_released():
			if dragged_card:
				on_drag_end()


	
func raycast_slot() -> CardSlot:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = SLOT_MASK
	var result = space_state.intersect_point(parameters)
	# Check and sort
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

# Drag logic
func on_drag_start(card: Card):
	dragged_card = card
	dragged_card.scale = Vector2(1,1)
	
func on_drag_end():
	var saved_card : Card = dragged_card;
	dragged_card = null
	
	saved_card.scale = Vector2(1.05,1.05)
	var card_slot = raycast_slot()
	if !card_slot or card_slot.slot_number == saved_card.slot or !player_field.try_place_card(saved_card, card_slot.slot_number):
		player_field.return_to_slot(saved_card)

# Card logic
func on_card_hovered(card: Card):
	if !card_hovered:
		card.scale = Vector2(1.05,1.05)
		card_hovered = card
		card.z_index = 2

func on_card_hovered_off(card: Card):
	if !dragged_card:
		card.scale = Vector2(1,1)
		card.z_index = 1
		if card_hovered == card:
			card_hovered = null
	

func connect_card(card: Card):
	card.connect("mouse_enter", on_card_hovered)
	card.connect("mouse_exit", on_card_hovered_off)
