class_name CardInfo
extends Control

@onready var stat_parent : Control = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var aux_info : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/AuxInfo
@onready var card_name : RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/CardName
@onready var adb : AbilityDB = $"../AbilityDB"

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
		
func modulate_stat(stat:String, val, default, str : String):
	var xstat = stat_map[stat]
	xstat.stat_val = str
	if val < default:
		xstat.modulate = Color.INDIAN_RED
	else:
		xstat.modulate = Color.WHITE

func project_card(card:Card):
	stat_map["Attack"].stat_val = str(card.unit.attack)
	modulate_stat("Health", card.current_health, card.unit.health, str(card.current_health) + "/" + str(card.unit.health))
	modulate_stat("Initiative", card.current_initiative, card.unit.initiative, str(card.current_initiative))
		
	card_name.text = card.unit.tag.to_upper().replacen("_", " ")
	aux_info.text = ""
	
	for a in card.unit.abilities:
		var ab : Ability = adb.abilities[a].instantiate()
		aux_info.text += ab.ability_name + ", "
	aux_info.text = aux_info.text.trim_suffix(", ")
