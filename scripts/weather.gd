class_name Weather
extends Node

@export var ability_name: String = "Unnamed Ability"
@export var description: String = ""
@export var icon : Texture2D = preload("res://textures/sun.png")

func visualize(_battlefield : BattleField) -> void:
	pass

func reset_visualize(_battlefield : BattleField) -> void:
	pass

func predict(_battlefield : BattleField) -> Dictionary:
	return {}

# Called on both attacker and defender
func apply(_battlefield : BattleField, state : Dictionary) -> void:
	pass

func revert(_battlefield : BattleField) -> void:
	pass
