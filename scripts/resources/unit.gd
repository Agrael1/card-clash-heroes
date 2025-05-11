class_name Unit
extends Resource

@export var sprite : Texture2D

@export_group("Unit Stats")
@export var tag: String
@export var health: int
@export var attack: int
@export var initiative: float
@export var meele: bool

@export_group("Shop Stats")
@export var max_count: int
@export var cost: int
