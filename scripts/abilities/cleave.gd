class_name Cleave
extends Ability

var line : Line2D

func _ready() -> void:
	# Configure the line
	line = Line2D.new()
	line.default_color = Color(1, 0, 0)  # Blue color
	line.width = 8.0
	
	# Add points to the line
	line.add_point(Vector2(100, 100))
	line.add_point(Vector2(200, 200))
	line.z_index = 10
	add_child(line)
	line.visible = false

# Called only from attacker, target viz
func visualize(caster : Card, target : Card, battlefield : BattleField) -> void:
	var slot : int = target.slot
	var field : PlayerField = battlefield.enemy_field
	var behind : CardSlot = field.get_behind(slot)
	if !validate(caster, target, battlefield):
		return
	
	# there is an enemy behind
	var r1 : Rect2 = target.get_global_rect()
	var r2 : Rect2 = behind.get_global_rect()
	var from = r1.get_center() 
	var to = r2.get_center() 
	
	line.visible = true
	line.points[0] = line.to_local(from)
	line.points[1] = line.to_local(to)

func reset_visualize() -> void:	
	line.visible = false

func validate(_caster : Card, target : Card, battlefield : BattleField) -> bool:
	var behind = battlefield.enemy_field.get_behind(target.slot)
	return target.is_enemy() && behind && !behind.is_empty() && \
	(target.card_state == Card.CardSelection.ENEMY_FULL || \
	target.card_state == Card.CardSelection.ENEMY_PENALTY)	

func predict(caster : Card, target : Card, battlefield : BattleField) -> Dictionary:
	var behind = battlefield.enemy_field.get_behind(target.slot)
	
	var damage = int(caster.unit.attack * caster.number / 2.0)
	var damage_result = behind.card_ref.calc_damage(damage)
	return {"damage" : damage_result[2], "target" : behind.slot_number}

func apply(caster : Card, _target : Card, battlefield : BattleField, state : Dictionary) -> void:
	var target_slot : int = state["target"]
	var field = battlefield.get_opponent_field_for(caster)
	var target : Card = field.get_at(target_slot).card_ref
	
	var old_num = target.number
	var damage_result = target.set_damage(state["damage"])
	
	var clog = battlefield.combat_log
	if target.is_enemy():
		clog.add_combat_event("Your {unit_a} attacked enemy {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":target.unit.tag.to_upper(),
			"dmg":damage_result[2],
			"kill":old_num - damage_result[0]}))
	else:
		clog.add_combat_event("Enemy {unit_a} attacked your {unit_t}, dealt {dmg} damage, killed {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":target.unit.tag.to_upper(),
			"dmg":damage_result[2],
			"kill":old_num - damage_result[0]}))
			
	if target.number == 0:
		battlefield.atb_bar.trim_card(target)
		battlefield.get_field_of(target).grid[target.slot].reset_card()
		target.free()
