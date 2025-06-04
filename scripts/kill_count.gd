class_name KillCount
extends Node2D

const SELF_SCENE = preload("res://objects/kill_count.tscn")

@export var pop_up_speed: float = 100.0  # Speed of upward movement
@export var fade_duration: float = 1.0   # How long the fade takes
@export var lifetime: float = 1.5        # Total lifetime before deletion
@export var distance: float = 150.0      # How far it moves up

var time_passed: float = 0.0
var initial_position: Vector2
var kill_count: int = 0

@onready var label = $Label

func _ready():
	# Store initial position
	initial_position = position
		
	# Set the kill count text
	label.text = ("+" if kill_count > 0 else "") + str(kill_count)
	if kill_count > 0:
		label.add_theme_color_override("font_color", Color.LIME_GREEN)
	
func _process(delta):
	# Update time
	time_passed += delta
	
	# Calculate movement - move upward
	position = initial_position - Vector2(0, distance * (time_passed / lifetime))
	
	# Calculate fade - start fading after a short delay
	var fade_start = lifetime - fade_duration
	if time_passed > fade_start:
		var fade_progress = (time_passed - fade_start) / fade_duration
		modulate.a = 1.0 - fade_progress
	
	# Remove the node when animation is complete
	if time_passed >= lifetime:
		queue_free()
