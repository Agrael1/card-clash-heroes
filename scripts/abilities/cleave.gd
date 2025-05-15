class_name Cleave
extends Ability

var line = Line2D.new()

func init(parent):
	# Configure the line
	line.default_color = Color(1, 0, 0)  # Blue color
	line.width = 8.0
	
	# Add points to the line
	line.add_point(Vector2(100, 100))
	line.add_point(Vector2(200, 200))
	line.z_index = 10
	parent.add_child(line)
	line.visible = false

func visualize(_caster : Card, battlefield : BattleField, target : Card):
	var slot = target.slot
	var field = battlefield.enemy_field
	if !battlefield.is_enemy(target) || slot < field.field_width:
		return false
	
	var behind : CardSlot = battlefield.enemy_field.get_at(slot % field.field_width)
	if behind.is_empty():
		return false
	
	# there is an enemy behind
	var r1 : Rect2 = target.get_global_rect()
	var r2 : Rect2 = behind.get_global_rect()
	var from = r1.get_center() 
	var to = r2.get_center() 
	
	line.visible = true
	line.points[0] = line.to_local(from)
	line.points[1] = line.to_local(to)
	return true

func reset_visualize():
	line.visible = false

# Executed on both peers
func execute(caster : Card, battlefield : BattleField, target : Card):
	var slot = target.slot
	var field = battlefield.enemy_field
	var enemy = battlefield.is_enemy(target)
	
	var behind : CardSlot = battlefield.enemy_field.get_at(slot % field.field_width)
	if behind.is_empty():
		return
	
	# warning-ignore:integer_division
	var damage = caster._unit.attack * caster.number / 2
	
	# If enemy -> local execution
	battlefield.attack_card(caster, behind, damage, enemy)
	
