class_name PlayerField
extends Container

@export var mirrored : bool = false
@export var field_width : int = 5
@export var field_height : int = 2
@export var slot_object = preload("res://objects/card_slot.tscn")

@onready var card_manager = $"../../CardManager"
@onready var root : GridContainer = $"."
@onready var ability_db_ref = $"../../AbilityDB"

var card_db_ref : CardDB = preload("res://resources/card_db.tres")
var race : String
var grid : Array[CardSlot] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid.resize(field_width * field_height)
	
	for i in range(field_width * field_height):
		var slot = slot_object.instantiate()
		slot.name = "slot_" + str(i)
		slot.slot_number = grid.size() - i - 1 if mirrored else i
		
		# Mirror slots in the grid
		grid[slot.slot_number] = slot
		add_child(slot)
	
	root.columns = field_width
	

#region public
func reset_slot(slot_num:int):
	if slot_num >= 0 and slot_num < grid.size():
		grid[slot_num].reset_card()

func find_card(card_tag:String) -> Card:
	for i in range(0, grid.size()):
		var slot = grid[i]
		if slot.same_as(card_tag):
			return slot.card_ref
	return null

func find_empty_slot()->CardSlot:
	for i in range(0, grid.size()):
		var slot = grid[i]
		if !slot.card_ref:
			return slot
	return null

func return_to_slot(card:Card):
	var slot_num : int = card.slot
	var slot : CardSlot = grid[slot_num]
	if slot_num >= 0 and slot_num < grid.size():
		slot.place_card(card)

func is_empty():
	for slot:CardSlot in grid:
		if !slot.is_empty():
			return false
	return true

func try_place_card(card:Card, slot_num:int) -> bool:
	var slot = grid[slot_num]
	if slot.is_empty():
		reset_slot(card.slot)
		slot.set_card(card)
		return true
	
	if slot.same_as(card.unit.tag):
		card.number += slot.card_ref.number
		var freed_card = slot.card_ref
		reset_slot(card.slot)
		slot.set_card(card)
		freed_card.queue_free()
		return true
	return false

func get_at(index:int) -> CardSlot:
	return grid[index]
	
func get_in_front(index : int) -> CardSlot:
	var new_idx = index - field_width
	return null if new_idx < 0 else grid[new_idx]

func get_behind(index : int) -> CardSlot:
	var new_idx = index + field_width
	return null if new_idx >= grid.size() else grid[new_idx]
	
func settle():
	for slot:CardSlot in grid:
		if slot.is_empty(): continue
		slot.card_ref.settle(ability_db_ref)
#endregion


#region serialize
func export():
	# Export the current state of the field to an array
	var export_data = []
	export_data.resize(field_width * field_height)
	
	for i in range(0, grid.size()):
		var slot = grid[i]
		if slot.card_ref:
			export_data[i] = slot.card_ref.export() # Format: [card_tag, card_number, card_slot]
		else:
			export_data[i] = null
	return export_data

func import(race : String,  data : Array):
	for i in range(0, grid.size()):
		var slot = grid[i]
		var card_data = data[i]
		if card_data == null:
			continue;
		
		# Instantiate card
		var card : Card = Card.SELF_SCENE.instantiate()
		card.collision_mask = Card.CARD_MASK_ENEMY_OFFSET
		card.unit = card_db_ref.races[race][card_data["unit"]]
		card.number = card_data["number"]
		
		card_manager.add_child(card)
		slot.set_card(card)
#endregion
