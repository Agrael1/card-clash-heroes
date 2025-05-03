extends Control

const CARD_PATH = "res://objects/card.tscn"
const CARD_MASK = 0
const SHOP_MASK = 2

var card_db_ref : CardDB = preload("res://resources/card_db.tres")
@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var card_manager = $"../CardManager"

func is_card(item):
	return item is Card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var container_array = $MarginContainer/GridContainer
	var card_array : Array[String] = card_db_ref.units_egypt_names
	for i in range(0, card_array.size()):
		var card_name = card_array[i]
		var card : Card = preload(CARD_PATH).instantiate()
		card.name = card_name + "_" + str(i)
		card.unit = card_db_ref.units_egypt[card_name]
		card.collision_mask = SHOP_MASK
		card.connect("mouse_click", on_card_clicked.bind(i))

		# Add the card to the container
		container_array.add_child(card)

func on_card_clicked(card: Card, bind : int):
	var same_card : Card = player_field.find_card(card.unit.tag)
	if same_card != null:
		same_card.number = same_card.number + 1
		return
	
	# if there is no such unit, find an empty slot
	var empty_slot : CardSlot = player_field.find_empty_slot()
	if !empty_slot:
		print("No empty space")
		return
	
	var new_card : Card = card.duplicate();
	card_manager.add_child(new_card)
	new_card.number = 1
	new_card.collision_mask = CARD_MASK
	empty_slot.set_card(new_card)
