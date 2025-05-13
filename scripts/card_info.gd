class_name CardInfo
extends Control

@onready var stat_parent : Control = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var aux_info : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/AuxInfo
@onready var card_name : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/CardName

const stats : Array[String] = [
	"Attack",
	"Health",
	"Initiative"
]

var stat_map : Dictionary[String, StatLine] = {}

func _ready() -> void:
	# Get all children
	var lines : Array[Node] = stat_parent.get_children().filter(func(x):return x is StatLine)
	assert(lines.size() == stats.size())
	for i in range(0, stats.size()):
		var stat : StatLine = lines[i]
		stat_map[stat.name] = stat
		stat.stat_name = stat.name
		

func project_card(card:Card):
	stat_map["Attack"].stat_val = str(card.unit.attack)
	stat_map["Health"].stat_val = str(card.current_health) + "/" + str(card.unit.health)
	stat_map["Initiative"].stat_val = str(card.unit.initiative)
	
	card_name.text = card.unit.tag.to_upper().replacen("_", " ")
	
	aux_info.text = "Melee" if card.unit.meele else "Shooter";
