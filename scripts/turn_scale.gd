class_name TurnScale
extends Control

@export var player_field: PlayerField
@export var enemy_field: PlayerField

@onready var card_parent: Node = $Panel/MarginContainer/HBoxContainer
@onready var current_turn_card: Card = $Panel2/Card
@onready var card_manager : CardManager = $"../CardManager"
@onready var battle_field : BattleField = $"../BattleField"

class CardRef:
	var ref: Card
	var belongs_to_player: bool
	var current_atb : float
	var atb_increment : float
	
	func _init(inref: Card, inbelongs: bool) -> void:
		self.ref = inref
		self.belongs_to_player = inbelongs
		self.atb_increment = inref.unit.initiative / 100
		
	func duplicate():
		var x = CardRef.new(self.ref, self.belongs_to_player)
		x.current_atb = self.current_atb
		return x

var _card_refs: Array[CardRef]

var _cache_refs : Array
	

func predict():
	_cache_refs.resize(15)	
	
	var units_copy: Array[CardRef]
	units_copy.resize(_card_refs.size())
	for i in range(0, _card_refs.size()):
		units_copy[i] = _card_refs[i].duplicate()
	
	
	for i in range(0, _cache_refs.size()):
		# Get least time
		var next_turn_times = []
		for j in range(0, units_copy.size()):
			var unit = units_copy[j]
			var time_needed = (1.0 - unit.current_atb) / unit.atb_increment
			next_turn_times.append({"index": j, "time": time_needed})
		
		# sort
		next_turn_times.sort_custom(func(a,b):return a["time"]<b["time"])
		
		# get the smallest
		var next_unit_turn = next_turn_times[0]
		var time_to_next = next_unit_turn["time"]
		var next_unit_idx = next_unit_turn["index"]
		
		_cache_refs[i] = _card_refs[next_unit_idx]
		
		# Advance time for all units
		for j in range(0, units_copy.size()):
			var unit = units_copy[j]
			unit.current_atb += unit.atb_increment * time_to_next
			
			if next_unit_idx == j:
				unit.current_atb = 0.0
			elif unit.current_atb > 0.9999:
				unit.current_atb = 0.9999
	
func repredict():
	pass

func populate_atb_bar() -> void:
	_card_refs = []
	
	# Set your cards
	for card_slot: CardSlot in player_field.grid:
		if card_slot.card_ref:
			_card_refs.append(CardRef.new(card_slot.card_ref, true))
			
	# Set enemy cards
	for card_slot: CardSlot in enemy_field.grid:
		if card_slot.card_ref:
			_card_refs.append(CardRef.new(card_slot.card_ref, false))
			
	
	for ref:CardRef in _card_refs:
		ref.current_atb = randf_range(0, 0.25)
	
	_card_refs.sort_custom(func(a: CardRef, b: CardRef) -> bool:
		return a.current_atb > b.current_atb
		)
	
	if not _card_refs.is_empty():
		predict()
		_make_ui_respect_state()
		card_parent.visible = true
		current_turn_card.visible = true
	else:
		push_error("no cards on either field?")

func export():
	var data = []
	data.resize(_card_refs.size())
	for i in range(0, _card_refs.size()):
		var ref = _card_refs[i]
		data[i] = {"slot": player_field.grid.size() - ref.ref.slot - 1, 
		"enemy":ref.belongs_to_player, 
		"current_atb":ref.current_atb} # intentional enemy is caught on the other side
	return data

func import(data): # format {"slot": int, "enemy":bool, "current_atb":float}
	_card_refs.resize(data.size())
	for i in range(0, _card_refs.size()):
		var enemy : bool= data[i]["enemy"] # on this side enemy is enemy
		var slot : int = data[i]["slot"]
		
		var card_ref
		if enemy:
			card_ref = enemy_field.grid[slot].card_ref
		else:
			card_ref = player_field.grid[slot].card_ref
			
		_card_refs[i] = CardRef.new(card_ref, !enemy)
		_card_refs[i].current_atb = data[i]["current_atb"]
	
	if not _card_refs.is_empty():
		predict()
		_make_ui_respect_state()
		card_parent.visible = true
		current_turn_card.visible = true
		
		var current : CardRef = first()
		if current.belongs_to_player:
			battle_field.on_card_turn(current.ref)
	else:
		push_error("no cards on either field?")

func first():
	return _cache_refs[0]
	
func action():
	pass

func wait():
	pass

func _make_ui_respect_state() -> void:
	assert(not _card_refs.is_empty())	
	
	var current = first()
	current_turn_card.unit = current.ref.unit
	current_turn_card.number = current.ref.number
	current_turn_card.sprite.modulate = Color.SKY_BLUE if current.belongs_to_player else Color.INDIAN_RED
	
	for i in range(1, _cache_refs.size()):
		var ref : CardRef = _cache_refs[i]
		var instance : Card = Card.SELF_SCENE.instantiate()
		instance.collision_mask = ref.ref.collision_mask
		instance.unit = ref.ref.unit
		instance.number = ref.ref.number
		
		# it is still a card
		card_parent.add_child(instance)
		instance.sprite.modulate = Color.SKY_BLUE if ref.belongs_to_player else Color.INDIAN_RED
		card_manager.connect_card(instance)
