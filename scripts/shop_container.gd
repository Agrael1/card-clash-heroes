class_name ShopContainer
extends PanelContainer

var shop : Shop
@onready var card_ref : Card = $MarginContainer/HBoxContainer/Card
@onready var number_box : LineEdit = $MarginContainer/HBoxContainer/VBoxContainer/LineEdit
var final_text = ""

func create(in_shop : Shop, unit):
	shop = in_shop
	card_ref.unit = unit
	card_ref.mouse_click.connect(on_card_clicked)



func on_card_clicked(card: Card, mouse_button:int):
	if !mouse_button == MOUSE_BUTTON_RIGHT: return
	
	var price = card.unit.cost
	var number = final_text.to_int()
	if number <= 0:
		return
		
	var same_card : Card = shop.player_field.find_card(card.unit.tag)
	if same_card != null:
		same_card.number = same_card.number + number
		final_text = "0"
		number_box.text = final_text
		return
	
	# if there is no such unit, find an empty slot
	var empty_slot : CardSlot = shop.player_field.find_empty_slot()
	if !empty_slot:
		print("No empty space")
		return
	
	var new_card : Card = card.duplicate();
	shop.card_manager.add_child(new_card)
	new_card.number = number
	new_card.collision_mask = Shop.CARD_MASK
	empty_slot.set_card(new_card)
	
	final_text = "0"
	number_box.text = final_text


func validate_gold(old_num:int, new_num:int)->bool:
	var old_gold = old_num * card_ref.unit.cost
	var new_gold = new_num * card_ref.unit.cost
	var ext = shop.gold + old_gold - new_gold
	if ext >= 0:
		shop.gold = ext
		return true
	return false

func _on_line_edit_text_changed(new_text: String) -> void:
	if !new_text.is_valid_int():
		number_box.text = final_text
		return
		
	var old_num = final_text.to_int()
	var new_num = new_text.to_int()
	var res = validate_gold(old_num, new_num)
	if res:
		final_text = new_text
	number_box.text = final_text
	
	

func _on_up_pressed() -> void:
	var num = number_box.text.to_int()
	var new_num = num + 1
	var val = validate_gold(num, new_num)
	if val:
		number_box.text = str(new_num)
		final_text = number_box.text


func _on_down_pressed() -> void:
	var num = number_box.text.to_int()
	var new_num = max(num - 1, 0)
	var val = validate_gold(num, new_num)
	if val:
		number_box.text = str(new_num)
		final_text = number_box.text
