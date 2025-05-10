class_name CardManager
extends Node2D

const CARD_MASK = 1 << 0
const SLOT_MASK = 1 << 1
const SHOP_MASK = 1 << 2
const CARD_MASK_ENEMY = 1 << 4

var dragged_card : Card
var card_hovered : Card
var screen_size : Vector2
var block_free_move : bool = false

@onready var player_field: PlayerField = $"../MarginContainer/PlayerField"
@onready var battle_field : BattleField = $"../BattleField"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if dragged_card:
		var mouse_pos = get_global_mouse_position()
		dragged_card.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y)) - dragged_card.size / 2
		
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			raycast_at_cursor(CARD_MASK if !block_free_move else CARD_MASK_ENEMY | SLOT_MASK)
		if event.is_released():
			if dragged_card:
				on_drag_end()

func on_raycast_card(card:Card):
	if !block_free_move: # prep phase
		on_drag_start(card)
		
func on_raycast_enemy(card:Card):
	battle_field.try_attack_at(card.slot)

func on_raycast_slot(slot:CardSlot):
	battle_field.move_to_slot(slot)

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


# Function to sort by y position
func first_by_z(cards):
	var first = cards[0]
	var first_z_index = first.collider.get_parent().z_index
	
	for i in range(1, cards.size()):
		var card = cards[i].collider.get_parent()
		if card.z_index > first_z_index:
			first = cards[i]
	return first

func raycast_at_cursor(collision_mask:int = CARD_MASK):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = collision_mask
	var result = space_state.intersect_point(parameters)
	# Check and sort
	if result.size() > 0:
		var first = first_by_z(result)
		var result_mask = first.collider.collision_mask
		var output = first.collider.get_parent()
		match result_mask:
			CARD_MASK:
				on_raycast_card(output)
			CARD_MASK_ENEMY:
				on_raycast_enemy(output)
			SLOT_MASK:
				on_raycast_slot(output)
				
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
