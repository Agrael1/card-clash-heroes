class_name CardDB
extends Resource

@export var units_egypt : Dictionary[String, Unit] = {
	"peasant" : preload("res://resources/peasant.tres"),
	"archer" : preload("res://resources/archer.tres")
}
@export var units_egypt_names : Array[String] = [
	"peasant","archer","peasant","peasant","peasant"
]
