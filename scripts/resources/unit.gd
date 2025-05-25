class_name Unit
extends Resource

@export var sprite : Texture2D = null

@export_group("Unit Stats")
@export var tag: String = "Unit"
@export var health: int = 0
@export var attack: int = 0
@export var initiative: float = 0.0
@export var abilities : Array[String] = []

@export_group("Shop Stats")
@export var max_count: int = 0
@export var cost: int = 0
