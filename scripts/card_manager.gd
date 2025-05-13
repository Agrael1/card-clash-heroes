class_name CardManager
extends Node2D

const CARD_MASK = 1 << 0
const SLOT_MASK = 1 << 1
const SHOP_MASK = 1 << 2
const CARD_MASK_ENEMY = 1 << 4

const Z_DRAG = 4
const Z_NORMAL = 0

var dragged_card : Card
var card_hovered : Card
var watched_card : Card
var screen_size : Vector2
var block_free_move : bool = false

@onready var player_field: PlayerField = $"../MarginContainer/PlayerField"
@onready var battle_field : BattleField = $"../BattleField"
@onready var card_info : CardInfo = $"../CardInfo"
@onready var tooltip : Tooltip = $"../Tooltip"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if dragged_card:
		var mouse_pos = get_global_mouse_position()
		dragged_card.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y)) - dragged_card.size / 2
		
	if tooltip.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip.position = mouse_pos + Vector2(10, 10) 
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			tooltip.visible = false
			if event.is_pressed():
				raycast_at_cursor(CARD_MASK if !block_free_move else CARD_MASK_ENEMY | SLOT_MASK)
			if event.is_released():
				if dragged_card:
					on_drag_end()
					
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				raycast_at_cursor(CARD_MASK if !block_free_move else CARD_MASK_ENEMY | CARD_MASK, MOUSE_BUTTON_RIGHT)
				return
				
			if event.is_released() and watched_card:
				watched_card = null
				card_info.visible = false
		

func on_raycast_card(card:Card, right_click:bool = false):
	if !block_free_move: # prep phase
		if !right_click:
			on_drag_start(card)
		else:
			card.number-=1
			if card.number == 0:
				card.queue_free()
	else: # fight phase
		if right_click:
			watched_card = card
			card_info.visible = true
			card_info.project_card(watched_card)
		
func on_raycast_enemy(card:Card, right_click:bool = false):
	if right_click:
		watched_card = card
		card_info.visible = true
		card_info.project_card(watched_card)
		return
		
	battle_field.try_attack_at(card.slot)

func on_raycast_slot(slot:CardSlot):
	battle_field.move_to_slot(slot)

# Drag logic
func on_drag_start(card: Card):
	dragged_card = card
	dragged_card.scale = Vector2(1,1)
	dragged_card.z_index = Z_DRAG
	
func on_drag_end():
	var saved_card : Card = dragged_card;
	dragged_card.z_index = Z_NORMAL
	dragged_card = null
	
	saved_card.scale = Vector2(1.05,1.05)
	var card_slot = raycast_slot()
	if !card_slot or card_slot.slot_number == saved_card.slot or !player_field.try_place_card(saved_card, card_slot.slot_number):
		player_field.return_to_slot(saved_card)
	
	# Raycast underneath
	var result : Card = raycast_at_cursor(CARD_MASK, 0, true)
	if result:
		on_card_hovered(result)


# Card logic
func on_card_hovered(card: Card):
	if !dragged_card:
		card.scale = Vector2(1.05,1.05)
		card_hovered = card
		card.z_index = 2
		if block_free_move and card.card_state == Card.Outline.ENEMY_FULL:
			var dmg_kills : Array = battle_field.on_enemy_hover(card)
			if dmg_kills:
				var dmg = dmg_kills[0]
				var kills = dmg_kills[1]
				tooltip.label.text = "Damage: {dmg}\nKills: {kills}".format({"dmg": dmg, "kills":kills})
				tooltip.visible = true

func on_card_hovered_off(card: Card):
	if !dragged_card:
		card.scale = Vector2(1,1)
		card.z_index = 1
		if card_hovered == card:
			card_hovered = null
	tooltip.visible = false

func connect_card(card: Card):
	card.mouse_enter.connect(on_card_hovered)
	card.mouse_exit.connect(on_card_hovered_off)

# Function to sort by y position
func first_by_z(cards):
	var first = cards[0]
	var first_z_index = first.collider.get_parent().z_index
	
	for i in range(1, cards.size()):
		var card = cards[i].collider.get_parent()
		if card.z_index > first_z_index:
			first = cards[i]
	return first

func raycast_at_cursor(collision_mask:int = CARD_MASK, button:int = MOUSE_BUTTON_LEFT, block : bool = false):
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
		if !block:
			match result_mask:
				CARD_MASK:
					on_raycast_card(output, button == MOUSE_BUTTON_RIGHT)
				CARD_MASK_ENEMY:
					on_raycast_enemy(output, button == MOUSE_BUTTON_RIGHT)
				SLOT_MASK:
					on_raycast_slot(output)
		return output
	return null
	
				
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
