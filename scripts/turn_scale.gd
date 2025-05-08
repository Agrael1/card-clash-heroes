class_name TurnScale
extends Control

@export var player_field: PlayerField
@export var enemy_field: PlayerField

@onready var card_parent: Node = $Panel/MarginContainer/HBoxContainer
@onready var current_turn_card: Card = $Panel2/Card

class CardRef:
	var ref: Card
	var belongs_to_player: bool
	
	func _init(inref: Card, inbelongs: bool) -> void:
		self.ref = inref
		self.belongs_to_player = inbelongs

var _card_refs: Array[CardRef]

func populate_atb_bar() -> void:
	_card_refs = []
	for card_slot: CardSlot in player_field.grid:
		if card_slot.card_ref:
			_card_refs.append(CardRef.new(card_slot.card_ref, true))
	for card_slot: CardSlot in enemy_field.grid:
		if card_slot.card_ref:
			_card_refs.append(CardRef.new(card_slot.card_ref, false))
	
	# TODO: sort by initiative or something?
	_card_refs.sort_custom(func(a: CardRef, b: CardRef) -> bool:
		return a.ref.unit.health > b.ref.unit.health
		)
	
	if not _card_refs.is_empty():
		_make_ui_respect_state()
		card_parent.visible = true
		current_turn_card.visible = true
	else:
		push_error("no cards on either field?")

func _make_ui_respect_state() -> void:
	assert(not _card_refs.is_empty())
	current_turn_card.unit = _card_refs[0].ref.unit
	
	# make number of Card children match number of card refs
	var child_count_diff: int = card_parent.get_child_count() - _card_refs.size()
	if child_count_diff < 0:
		for i in abs(child_count_diff):
			card_parent.add_child(Card.SELF_SCENE.instantiate())
	elif child_count_diff > 0:
		var cards := card_parent.get_children()
		for i in range(cards.size() - child_count_diff, cards.size()):
			cards[i].queue_free()
	assert(card_parent.get_child_count() == _card_refs.size())
	
	# make all cards match sorted order
	for i in range(1, _card_refs.size()):
		var actual_card: Card = _card_refs[i].ref
		var display_card := card_parent.get_child(i) as Card
		if not display_card:
			push_warning("non card found in atb?")
			continue
		display_card.unit = actual_card.unit
		display_card.modulate = Color.BLUE if _card_refs[i].belongs_to_player else Color.RED
