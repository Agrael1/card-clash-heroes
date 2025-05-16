class_name Shop
extends Control

const CARD_MASK = 0
const SHOP_MASK = 2

var card_db_ref : CardDB = preload("res://resources/card_db.tres")
var card_container : PackedScene = preload("res://objects/shop_container.tscn")

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var card_manager = $"../CardManager"
@onready var gold_label = $ColorRect/HBoxContainer/RichTextLabel2
@onready var container_array = $MarginContainer/GridContainer

var _gold : int = 50
var gold : int :
	set(value):
		_gold = value
		if gold_label:
			gold_label.text = str(_gold)
	get:
		return _gold

# Called when the node enters the scene tree for the first time.
func open_for(race:String) -> void:
	var card_array : Array = card_db_ref.races_unit_names[race]
	for i in range(0, card_array.size()):
		var card_name = card_array[i]
		var card : ShopContainer = card_container.instantiate()
		container_array.add_child(card)
		card.create(self, card_db_ref.races[race][card_name])
		
		#card.name = card_name + "_" + str(i)
		#card.unit = card_db_ref.races[race][card_name]
		#card.collision_mask = SHOP_MASK
		#card.mouse_click.connect(on_card_clicked)

		# Add the card to the container

func on_card_clicked(card: Card, mouse_button:int):
	if !mouse_button == MOUSE_BUTTON_RIGHT: return
	
	var same_card : Card = player_field.find_card(card.unit.tag)
	var price = card.unit.cost
	if gold - price < 0:
		print("no money")
		return
	
	if same_card != null:
		gold -= price
		same_card.number = same_card.number + 1
		return
	
	# if there is no such unit, find an empty slot
	var empty_slot : CardSlot = player_field.find_empty_slot()
	if !empty_slot:
		print("No empty space")
		return
	
	gold -= price
	var new_card : Card = card.duplicate();
	card_manager.add_child(new_card)
	new_card.number = 1
	new_card.collision_mask = CARD_MASK
	empty_slot.set_card(new_card)

func sell(card:Card):
	card.number -= 1
	gold += card.unit.cost
