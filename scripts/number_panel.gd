extends Panel

var panel : Panel
var label : RichTextLabel

var _number: int = 0
@export var number: int:
	set(value):
		_number = value
		if !panel: return;
		if value == 0 and panel.visible:
			panel.hide()
			return;
		if value > 1000:
			label.text = str(int(value / 1000)) + "K"
		else:
			label.text = str(value)
		if !panel.visible:
			panel.show()
	get:
		return _number

func _ready() -> void:
	panel = $"."
	label = $RichTextLabel
	set_number(_number)

func set_number(new_num : int):
	number = new_num
	
