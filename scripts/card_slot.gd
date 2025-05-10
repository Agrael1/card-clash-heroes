class_name CardSlot
extends Panel

@export var slot_number : int = 0
@export var card_ref : Card

func set_card(card : Card):
	card_ref = card
	_place_card(card)
	card.slot = slot_number

func reset_card():
	card_ref = null

func _place_card(card: Card):
	var rect = get_global_rect()
	card.position = rect.position

func is_empty() -> bool:
	return card_ref == null

func same_as(card_tag : String):
	return !is_empty() and card_tag == card_ref.unit.tag
