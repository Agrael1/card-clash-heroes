extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var container_array = $Panel/MarginContainer/GridContainer
	var children_array = container_array.get_children()
	for i in range(0, children_array.size()):
		var child = children_array[i]
		if child is Card:
			var card : Card = child as Card;
			card.connect("mouse_click", on_card_clicked.bind(i))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_card_clicked(card: Card, bind : int):
	print("Clicked on:", bind)
