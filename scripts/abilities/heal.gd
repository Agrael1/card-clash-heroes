class_name Heal
extends Ability

@export var amount = 1

func init(parent):
	pass

func visualize(caster : Card, battlefield : BattleField, target : Card):
	return true

func reset_visualize():
	pass

# Executed on both peers
func execute(caster : Card, battlefield : BattleField, target : Card):
	var enemy = battlefield.is_enemy(caster) # If not enemy -> local execution
	
	if enemy:
		# take slot to the left
		var slot = caster.slot - 1
		if slot < 0 or slot % battlefield.enemy_field.field_width == battlefield.enemy_field.field_width - 1:
			return
		
		var slot_handle = battlefield.enemy_field.get_at(slot)
		if !slot_handle || slot_handle.is_empty():
			return
		battlefield.heal_card(caster, slot_handle, amount * caster.number, !enemy)
	else:
		var slot = caster.slot + 1
		if slot % battlefield.player_field.field_width == 0:
			return
		var slot_handle = battlefield.player_field.get_at(slot)
		if !slot_handle || slot_handle.is_empty():
			return
			
		battlefield.heal_card(caster, slot_handle, amount * caster.number, !enemy)
