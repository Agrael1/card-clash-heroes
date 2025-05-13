class_name CombatLog
extends Control

@onready var combat_log: RichTextLabel = $RichTextLabel


func add_combat_event(event_text: String):
	# Add a new event to the combat log
	combat_log.append_text("[color=yellow]" + event_text + "[/color]\n")
