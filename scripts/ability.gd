class_name Ability
extends Resource

@export var ability_name: String = "Unnamed Ability"
@export var description: String = ""
@export var viz_type : VizType = VizType.NONE

enum VizType{NONE, PASSIVE, TARGET}

func init(parent):
	pass

func execute(caster : Card, _battlefield : BattleField, _target : Card):
	print(ability_name + " executed by " + caster.name)
	return true

func visualize(caster : Card, _battlefield : BattleField, _target : Card):
	print(ability_name + " executed by " + caster.name)
	return true
	
func reset_visualize():
	pass
