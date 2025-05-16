class_name CardSlot
extends Panel

const DEBUG_EnableSlotCounter = true

@export var slot_number : int = 0
@export var card_ref : Card

@onready var slot_dbg : RichTextLabel = $DEBUG_SlotNum

func _ready() -> void:
	slot_dbg.visible = DEBUG_EnableSlotCounter
	slot_dbg.text = str(slot_number)

func set_card(card : Card):
	card_ref = card
	place_card(card)
	card.slot = slot_number

func reset_card():
	card_ref = null

func place_card(card: Card):
	var rect = get_global_rect()
	card.position = rect.position

func is_empty() -> bool:
	return card_ref == null

func same_as(card_tag : String):
	return !is_empty() and card_tag == card_ref.unit.tag
