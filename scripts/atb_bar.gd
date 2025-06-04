class_name TurnScale
extends Control

const MAX_PREDICT = 15

@export var player_field: PlayerField
@export var enemy_field: PlayerField

@onready var card_parent: Node = $Panel/ScrollContainer/MarginContainer/HBoxContainer
@onready var current_turn_card: Card = $Panel2/Card
@onready var card_manager : CardManager = $"../CardManager"
@onready var battle_field : BattleField = $"../BattleField"

class CardRef:
	signal current_time_changed(value:float)
	
	var parent = null
	var ref: Card
	var belongs_to_player: bool
	var atb_increment : float
	
	var _current_time : float
	var current_time: float:
		set(value):
			_current_time = value
			current_time_changed.emit(value)
		get:
			return _current_time
	
	func _init(inref: Card, inbelongs: bool) -> void:
		self.ref = inref
		self.belongs_to_player = inbelongs
		self.atb_increment = inref.unit.initiative / 100
		
	func update():
		self.atb_increment = self.ref.current_initiative / 100
				
	func duplicate():
		var x = CardRef.new(self.ref, self.belongs_to_player)
		x.current_time = self.current_time
		x.parent = self
		return x
		
	func _to_string() -> String:
		return "[CardRef: %s, time=%.2f, increment=%.2f]" % [ref.unit.tag, current_time, atb_increment]

var _current_refs : Array[CardRef] # Current refs
var _cache_refs : Array[CardRef] # Used for ATB cards
var _last_state : Array[CardRef] # Used for easy step


func _ready() -> void:
	for i in range(0, MAX_PREDICT - 1):
		var instance : CardViewATB = CardViewATB.SELF_SCENE.instantiate()
		instance.name = "ATBView" + str(i);
		card_parent.add_child(instance)
		card_manager.connect_card(instance.card_scene)


# Initial setup
func populate_atb_bar() -> void:
	_current_refs = []
	
	# Set your cards
	for card_slot: CardSlot in player_field.grid.filter(func(x):return x.card_ref):
			_current_refs.append(CardRef.new(card_slot.card_ref, true))

	# Set enemy cards
	for card_slot: CardSlot in enemy_field.grid.filter(func(x):return x.card_ref):
			_current_refs.append(CardRef.new(card_slot.card_ref, false))
	
	if _current_refs.is_empty():
		push_error("no cards on either field?")
		return

	# Sort them according to their time
	for ref:CardRef in _current_refs:
		ref.current_time = randf_range(0, 0.25)
	
	_sort_refs(_current_refs)
	_start_game()

func recalculate() -> void:
	for ref in _current_refs:
		if ref.ref: ref.update()
		
	_predict()
	_advance(_current_refs)
	_sync_ui()

func first():
	return _current_refs[0]

func action() -> void:
	# simple path - remove first and calculate next
	_cache_refs.pop_front()
	_current_refs[0].current_time = 0.0
	
	_advance(_last_state)
	_advance(_current_refs)
	_cache_refs.push_back(_last_state[0])
	_ui_advance()

func wait() -> void:
	# complex path
	_current_refs[0].current_time = 0.5
	_predict() # reset the whole ATB :(
	_advance(_current_refs)
	_sync_ui()

func trim_card(card : Card):
	_last_state = _trim(_last_state, card)
	_current_refs = _trim(_current_refs, card)
	
	var prev_size = _cache_refs.size()
	_ui_trim(card)
	
	_cache_refs = _trim(_cache_refs, card)
	var new_size = _cache_refs.size()
	for i in range(new_size, prev_size):
		_advance(_last_state)
		_cache_refs.push_back(_last_state[0])	
	_ui_compensate(new_size)

#region serialize
func export():
	var data = []
	data.resize(_current_refs.size())
	for i in range(0, _current_refs.size()):
		var ref = _current_refs[i]
		data[i] = {"slot": ref.ref.slot, 
		"enemy":ref.belongs_to_player, 
		"current_atb":ref.current_time} # intentional enemy is caught on the other side
	return data

func import(data): # format {"slot": int, "enemy":bool, "current_atb":float}
	_current_refs.resize(data.size())
	for i in range(0, _current_refs.size()):
		var enemy : bool= data[i]["enemy"] # on this side enemy is enemy
		var slot : int = data[i]["slot"]
		
		var card_ref
		if enemy:
			card_ref = enemy_field.grid[slot].card_ref
		else:
			card_ref = player_field.grid[slot].card_ref
			
		_current_refs[i] = CardRef.new(card_ref, !enemy)
		_current_refs[i].current_time = data[i]["current_atb"]
	
	if _current_refs.is_empty():
		push_error("no cards on either field?")
		return
	
	_start_game()
#endregion

#region private
func _sort_refs(refs : Array) -> void:
	refs.sort_custom(func(a: CardRef, b: CardRef) -> bool:
		return a.current_time > b.current_time
		)

func _sort_by_dt(refs: Array) -> void:
	refs.sort_custom(func(a : CardRef, b : CardRef):
		var dta = (1.0 - a.current_time) / a.atb_increment
		var dtb = (1.0 - b.current_time) / b.atb_increment
		return dta < dtb)

func _predict():
	for index in range(0, _current_refs.size()):
		_last_state[index] = _current_refs[index].duplicate()

	for index in range(0, _cache_refs.size()):
		_advance(_last_state)
		var f = _last_state[0]
		_cache_refs[index] = f
		_last_state[0].current_time = 0.0
		

func _advance(refs : Array):
	_sort_by_dt(refs)
	var xfirst = refs.front()
	var time_to_first = (1.0 - xfirst.current_time) / xfirst.atb_increment
	
	for ref : CardRef in refs:
		ref.current_time = min(ref.current_time + time_to_first * ref.atb_increment, 0.999)

func _trim(refs : Array, card : Card):
	return refs.filter(func(x): return x.ref != card)

func _start_game():
	_cache_refs.resize(MAX_PREDICT)	
	_last_state.resize(_current_refs.size())
	
	_predict()
	_advance(_current_refs)
	_sync_ui()
	
	card_parent.visible = true
	current_turn_card.visible = true
		
	var current : CardRef = first()
	if current.belongs_to_player:
		battle_field.on_card_turn(current.ref)
#endregion


#region private ui
func _sync_ui() -> void:
	assert(not _current_refs.is_empty())
	
	var current = first()
	current_turn_card.unit = current.ref.unit
	current_turn_card.number = current.ref.number
	current_turn_card.sprite.modulate = Color.SKY_BLUE if current.belongs_to_player else Color.INDIAN_RED
	
	for i in range(1, _cache_refs.size()):
		var ref : CardRef = _cache_refs[i]
		var instance : CardViewATB = card_parent.get_child(i - 1)
		instance.card_ref = ref.parent
		
		# it is still a card
		instance.card_scene.mouse_enter.connect(func(_card : Card):_ui_follow_card(ref))
		instance.card_scene.mouse_exit.connect(func(_card : Card):_ui_unfollow_card(ref))

func _ui_follow_card(card : CardRef):
	if card && is_instance_valid(card.ref):
		card.ref.pointer.visible = true
		card.ref.mouse_enter.emit(card.ref)
	
func _ui_unfollow_card(card : CardRef):
	if card && is_instance_valid(card) && card != battle_field.attacker_card:
		card.ref.pointer.visible = false
		card.ref.mouse_exit.emit(card.ref)
		
func _ui_advance()->void:
	var current = first()
	current_turn_card.unit = current.ref.unit
	current_turn_card.number = current.ref.number
	current_turn_card.sprite.modulate = Color.SKY_BLUE if current.belongs_to_player else Color.INDIAN_RED
	
	# move first child to the end
	var ref : CardRef = _cache_refs.back()
	var child : CardViewATB = card_parent.get_child(0)
	child.card_ref = ref.parent
	card_parent.move_child(child, card_parent.get_child_count() - 1)
	
func _ui_trim(card : Card):
	for i in range(_cache_refs.size() - 1, 0, -1):
		var ref : CardRef = _cache_refs[i]
		if ref.ref == card:
			# -1 because 0th ref is in other panel
			card_parent.move_child(card_parent.get_child(i - 1), card_parent.get_child_count() - 1)

func _ui_compensate(begin):
	for i in range(begin, _cache_refs.size()):
		var ref : CardRef = _cache_refs[i]
		var child : CardViewATB = card_parent.get_child(i - 1)
		child.card_ref = ref.parent
#endregion
