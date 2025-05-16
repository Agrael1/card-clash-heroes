class_name Heal
extends Ability

@export var amount : float = 1.0

var targets:Array[Card]

#region overrides
func _ready() -> void:
	targets.resize(1)

# Viz passive
func visualize(caster : Card, _target : Card, battlefield : BattleField) -> void:
	var target_card: Card = get_target_card(caster, battlefield)
	if !target_card: return
	target_card.card_state = Card.CardSelection.HEAL
	targets[0] = target_card

func reset_visualize() -> void:
	for t in targets.filter(func(c): return c != null):
		t.card_state = Card.CardSelection.NONE

func validate(caster : Card, _target : Card, battlefield : BattleField) -> bool:
	var tgt = get_target_card(caster, battlefield)
	return tgt == null || tgt.is_full()

func predict(caster : Card, _target : Card, _battlefield : BattleField) -> Dictionary:
	return {}

# Called on both attacker and defender
func apply(caster : Card, _target : Card, battlefield : BattleField, state : Dictionary) -> void:
	var heal = int(amount * caster.number)
	var tgt = get_target_card(caster, battlefield)
	var units_before = tgt.number
	var heal_result = tgt.set_heal(heal)
	var combat_log = battlefield.combat_log
	
	if !caster.is_enemy():
		combat_log.add_combat_event(" Your {unit_a} healed {unit_t} for {dmg}, resurrected {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":tgt.unit.tag.to_upper(),
			"dmg":heal_result[2],
			"kill":heal_result[0] - units_before}))
	else:
		combat_log.add_combat_event("Enemy {unit_a} healed {unit_t} for {dmg}, resurrected {kill}"
			.format({"unit_a":caster.unit.tag.to_upper(),
			"unit_t":tgt.unit.tag.to_upper(),
			"dmg":heal_result[2],
			"kill":heal_result[0] - units_before}))



func get_target_card(caster : Card, battlefield : BattleField) -> Card:
	var slot = caster.slot + 1
	var field = battlefield.get_field_of(caster)
	if slot % field.field_width == 0:
		return null
	var slot_handle = field.get_at(slot)
	if !slot_handle || slot_handle.is_empty():
		return null
		
	return slot_handle.card_ref
