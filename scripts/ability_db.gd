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
	if OS.has_feature("editor"):
		# In editor, load dynamically and also generate the static list
		get_scenes_from_directory(ABILITY_PATH)
		generate_static_list()
	else:
		# In export, use the generated static list
		load_from_static_list()

func generate_static_list():
	#var file = FileAccess.open("res://resources/ability_list.gd", FileAccess.WRITE)
	#if file:
		#file.store_string("# Auto-generated ability list\n")
		#file.store_string("const ABILITIES : Dictionary[String, PackedScene] = {\n")
		#
		#for ability_name in abilities:
			#file.store_string('    "%s": preload("res://resources/abilities/%s.tscn"),\n' % [ability_name, ability_name])
		#
		#file.store_string("}\n")
		#file.close()
		print("Generated static ability list")

func load_from_static_list():
	var AbilityList = load("res://resources/ability_list.gd")
	if AbilityList:
		abilities = AbilityList.ABILITIES.duplicate()
	else:
		push_error("Failed to load ability list!")
