class_name Rain
extends Weather

@onready var rain : GPUParticles2D = $GPUParticles2D
var applied = false

func _ready() -> void:
	if rain.process_material is ParticleProcessMaterial:
		var viewport_size = get_viewport().size
		var pm : ParticleProcessMaterial = rain.process_material
		
		pm.emission_box_extents = Vector3(viewport_size.x, 1,1)

func visualize(battlefield : BattleField) -> void:
	battlefield.forecast.image.texture = icon
	self.visible = true

func reset_visualize(battlefield : BattleField) -> void:
	battlefield.forecast.image.texture = preload("res://textures/sun.png")
	self.visible = false

func predict(_battlefield : BattleField) -> Dictionary:
	return {}

# Called on both attacker and defender
func apply(battlefield : BattleField, _state : Dictionary) -> void:
	if applied: return
	var ef = battlefield.enemy_field
	var pf = battlefield.player_field 
	
	for cs : CardSlot in ef.grid.filter(func(x:CardSlot):return !x.is_empty()):
		for a : Ability in cs.card_ref.abilities:
			if(a.ability_name == "Melee"):
				cs.card_ref.current_initiative = cs.card_ref.unit.initiative * 0.85
				break
	
	for cs : CardSlot in pf.grid.filter(func(x:CardSlot):return !x.is_empty()):
		for a : Ability in cs.card_ref.abilities:
			if(a.ability_name == "Melee"):
				cs.card_ref.current_initiative = cs.card_ref.unit.initiative * 0.85
				break
	
	battlefield.atb_bar.recalculate()
	applied = true
	

func revert(battlefield : BattleField) -> void:
	if !applied: return
	
	var ef = battlefield.enemy_field
	var pf = battlefield.player_field 
	
	for cs : CardSlot in ef.grid.filter(func(x:CardSlot):return !x.is_empty()):
		for a : Ability in cs.card_ref.abilities:
			if(a.ability_name == "Melee"):
				cs.card_ref.current_initiative = cs.card_ref.unit.initiative
	
	for cs : CardSlot in pf.grid.filter(func(x:CardSlot):return !x.is_empty()):
		for a : Ability in cs.card_ref.abilities:
			if(a.ability_name == "Melee"):
				cs.card_ref.current_initiative = cs.card_ref.unit.initiative
				break
		
	battlefield.atb_bar.recalculate()
	applied = false
