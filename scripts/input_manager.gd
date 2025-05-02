class_name InputManager extends Node2D

const CARD_MASK = 1 << 0
const SLOT_MASK = 1 << 1
const SHOP_MASK = 1 << 2

var card_manager : CardManager

func _ready() -> void:
	card_manager = $"../CardManager"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			raycast_at_cursor()
		if event.is_released():
			pass

func is_card(item):
	return item.collider.collision_mask == CARD_MASK;

# Function to sort by y position
func sort_by_z(cards):
	var filtered_cards = cards.filter(is_card)
	var first = filtered_cards[0].collider.get_parent()
	var first_z_index = first.z_index
	
	for i in range(1, filtered_cards.size()):
		var card = filtered_cards[i].collider.get_parent()
		if card.z_index > first_z_index:
			first = card
	return first

func raycast_at_cursor(collision_mask:int = CARD_MASK|SHOP_MASK):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = collision_mask
	var result = space_state.intersect_point(parameters)
	# Check and sort
	if result.size() > 0:
		var result_mask = result[0].collider.collision_mask
		match result_mask:
			CARD_MASK:
				card_manager.on_drag_start(sort_by_z(result))
			SHOP_MASK:
				print("Shop accessed")
