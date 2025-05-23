class_name Shop
extends Control

const CARD_MASK = 0
const SHOP_MASK = 2
const UnitScript = preload("res://scripts/resources/unit.gd")

@export var card_db_ref : CardDB
var card_container : PackedScene = preload("res://objects/shop_container.tscn")

@onready var player_field : PlayerField = $"../MarginContainer/PlayerField"
@onready var card_manager = $"../CardManager"
@onready var gold_label = $ColorRect/HBoxContainer/RichTextLabel2
@onready var container_array = $MarginContainer/GridContainer
@onready var card_info : CardInfo = $"../CardInfo"

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
		card.card_ref.number = card_db_ref.races[race][card_name].cost
		card.card_ref.number_panel.coin.visible = true
		card.card_ref.mouse_enter.connect(on_card_hover_on)
		card.card_ref.mouse_exit.connect(on_card_hover_off)
		
		card.tooltip_text = "Purchase"
		
		#push_warning("card_db_ref.races[race][card_name]" +  card_db_ref.races[race][card_name].get_class())
		card.create(self, card_db_ref.races[race][card_name])
		# Add the card to the container

func sell(card:Card):
	card.number -= 1
	gold += card.unit.cost

func on_card_hover_on(card : Card):
	card_info.visible = true
	card_info.project_card(card)
	
func on_card_hover_off(card : Card):
	card_info.visible = false
