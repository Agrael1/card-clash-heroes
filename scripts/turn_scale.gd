class_name TurnScale
extends Control

@export var player_field: PlayerField
@export var enemy_field: PlayerField

@onready var card_parent: Node = $Panel/ScrollContainer/MarginContainer/HBoxContainer
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

var _cache_refs : Array[CardRef]
var _last_state : Array[CardRef]
	

func predict():
	_cache_refs.resize(15)	
	
	_last_state.resize(_card_refs.size())
	for i in range(0, _card_refs.size()):
		_last_state[i] = _card_refs[i].duplicate()
	
	for i in range(0, _cache_refs.size()):
		advance(i)
		
	
func advance(insert_idx:int):
	# Get least time
	var next_turn_times = []
	for j in range(0, _last_state.size()):
		var unit = _last_state[j]
		var time_needed = (1.0 - unit.current_atb) / unit.atb_increment
		next_turn_times.append({"index": j, "time": time_needed})
		
		# sort
	next_turn_times.sort_custom(func(a,b):return a["time"]<b["time"])
		
		# get the smallest
	var next_unit_turn = next_turn_times[0]
	var time_to_next = next_unit_turn["time"]
	var next_unit_idx = next_unit_turn["index"]
		
	_cache_refs[insert_idx] = _last_state[next_unit_idx].duplicate()
		
		# Advance time for all units
	for j in range(0, _last_state.size()):
		var unit = _last_state[j]
		unit.current_atb += unit.atb_increment * time_to_next
			
		if next_unit_idx == j:
			unit.current_atb = 0.0
		elif unit.current_atb > 0.9999:
			unit.current_atb = 0.9999

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
		
		var current : CardRef = first()
		if current.belongs_to_player:
			battle_field.on_card_turn(current.ref)
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
	# simple path - remove first and calculate next
	_cache_refs.pop_front()
	_cache_refs.push_back(null)
	advance(_cache_refs.size() - 1)
	_ui_advance()
	return first()

func wait():
	# complex path - recalculate placement of the same ref
	pass

func trim_card(card : Card):
	_last_state = _last_state.filter(func(x: CardRef): return x.ref != card)
	var prev_size = _cache_refs.size()
	_ui_trim(card)
	_cache_refs = _cache_refs.filter(func(x): return x.ref != card)
	var new_size = _cache_refs.size()
	for i in range(new_size, prev_size):
		_cache_refs.push_back(null)
		advance(i)
	_ui_compensate(new_size)

func _ui_trim(card : Card):
	for i in range(_cache_refs.size() - 1, 0, -1):
		var ref : CardRef = _cache_refs[i]
		if ref.ref == card:
			# -1 because 0th ref is in other panel
			card_parent.move_child(card_parent.get_child(i - 1), card_parent.get_child_count() - 1)

func _ui_compensate(begin):
	for i in range(begin, _cache_refs.size()):
		var ref : CardRef = _cache_refs[i]
		var child : Card = card_parent.get_child(i - 1)
		child.collision_mask = ref.ref.collision_mask
		child.unit = ref.ref.unit
		child.number = ref.ref.number
		child.sprite.modulate = Color.SKY_BLUE if ref.belongs_to_player else Color.INDIAN_RED

func _ui_advance()->void:
	var current = first()
	current_turn_card.unit = current.ref.unit
	current_turn_card.number = current.ref.number
	current_turn_card.sprite.modulate = Color.SKY_BLUE if current.belongs_to_player else Color.INDIAN_RED
	
	# move first child to the end
	var ref : CardRef = _cache_refs.back()
	var child : Card = card_parent.get_child(0)
	child.collision_mask = ref.ref.collision_mask
	child.unit = ref.ref.unit
	child.number = ref.ref.number
	child.sprite.modulate = Color.SKY_BLUE if ref.belongs_to_player else Color.INDIAN_RED
	card_parent.move_child(child, card_parent.get_child_count() - 1)

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
