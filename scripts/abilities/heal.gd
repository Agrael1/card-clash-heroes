#class_name Heal
#extends Ability
#
#@export var amount = 1
#
#var targets:Array[Card]
#
##region overrides
#func init(_parent):
	#targets.resize(1)
#
#func visualize(caster : Card, battlefield : BattleField, _target : Card):
	#var target_card: Card = get_target_card(caster, battlefield)
	#if !target_card: return false
	#target_card.card_state = Card.CardSelection.HEAL
	#targets[0] = target_card
	#return true
#
#func reset_visualize():
	#for t in targets.filter(func(c): return c != null):
		#t.card_state = Card.CardSelection.NONE
#
## Executed on both peers
#func execute(caster : Card, battlefield : BattleField, _target : Card):
	#var enemy = battlefield.is_enemy(caster) # If not enemy -> local execution
	#var target_card : Card = get_target_card(caster, battlefield, enemy)
	#if !target_card: return
	#heal_card(caster, target_card, amount * caster.number, battlefield. combat_log, !enemy)
	#
##endregion
	#
#
#func get_target_card(caster : Card, battlefield : BattleField, enemy : bool = false) -> Card:
	#if enemy:
		## take slot to the left
		#var slot = caster.slot - 1
		#if slot < 0 or slot % battlefield.enemy_field.field_width == battlefield.enemy_field.field_width - 1:
			#return null
		#var slot_handle = battlefield.enemy_field.get_at(slot)
		#if !slot_handle || slot_handle.is_empty():
			#return null
		#
		#return slot_handle.card_ref
	#else:
		#var slot = caster.slot + 1
		#if slot % battlefield.player_field.field_width == 0:
			#return null
		#var slot_handle = battlefield.player_field.get_at(slot)
		#if !slot_handle || slot_handle.is_empty():
			#return null
			#
		#return slot_handle.card_ref
#
#func heal_card(attacker : Card, target_card : Card, damage : int, combat_log, local:bool):
	#var before : int = target_card.number
	#var heal_result : Array = target_card.set_heal(damage)
	#var units_resurrected = target_card.number - before
	#
	#if local:
		#combat_log.add_combat_event(" Your {unit_a} healed {unit_t} for {dmg}, resurrected {kill}"
			#.format({"unit_a":attacker._unit.tag.to_upper(),
			#"unit_t":target_card.unit.tag.to_upper(),
			#"dmg":heal_result[2],
			#"kill":units_resurrected}))
	#else:
		#combat_log.add_combat_event("Enemy {unit_a} healed {unit_t} for {dmg}, resurrected {kill}"
			#.format({"unit_a":attacker._unit.tag.to_upper(),
			#"unit_t":target_card.unit.tag.to_upper(),
			#"dmg":heal_result[2],
			#"kill":units_resurrected}))
