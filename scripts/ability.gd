class_name Ability
extends Resource

@export var ability_name: String = "Unnamed Ability"
@export var description: String = ""
@export var viz_type : VizType = VizType.NONE

enum VizType{NONE, PASSIVE, TARGET}

func init(parent : Node) -> void:
	pass

func visualize(_caster : Card, _target : Card, _battlefield : BattleField) -> void:
	pass

func reset_visualize() -> void:
	pass

func validate(_caster : Card, _target : Card, _battlefield : BattleField) -> bool:
	return false

func predict(_caster : Card, _target : Card, _battlefield : BattleField) -> Dictionary:
	return {}

# Called on both attacker and defender
func apply(_caster : Card, _target : Card, _battlefield : BattleField, state : Dictionary) -> void:
	pass
