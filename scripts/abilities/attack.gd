class_name Attack
extends Ability

func apply(caster : Card, target : Card, battlefield : BattleField, state : Dictionary) -> void:
	caster.z_index = CardManager.Z_DRAG
	
	var prev_attacker_pos = caster.position
	var old_num = target.number
	
	var tween = get_tree().create_tween()
	tween.tween_property(caster, "position", target.position, 0.2)
	await tween.finished
	
	
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
	
	if old_num - damage_result[0] > 0:
		on_unit_killed(target.position + target.size * 0.5, damage_result[0] - old_num, battlefield)
	
	if target.number == 0:
		battlefield.atb_bar.trim_card(target)
		battlefield.get_field_of(target).grid[target.slot].reset_card()
		target.free()
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(caster, "position", prev_attacker_pos, 0.3)
	await tween2.finished
	
	caster.z_index = CardManager.Z_NORMAL

func on_unit_killed(position: Vector2, kill_count: int, battlefield : BattleField):
	# Instance the scene
	var popup = KillCount.SELF_SCENE.instantiate()
	popup.position = position
	popup.kill_count = kill_count
	battlefield.add_child(popup)
