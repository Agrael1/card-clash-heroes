class_name AbilityDB
extends Node

const ABILITY_PATH := "res://resources/abilities"

@export var abilities : Dictionary[String, PackedScene] = {}

func get_scenes_from_directory(path: String):
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tscn"):
				var ability_path = path + "/" + file_name
				abilities[file_name.split(".")[0]] = load(ability_path)
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path: " + path)

func _init() -> void:
	get_scenes_from_directory(ABILITY_PATH)
