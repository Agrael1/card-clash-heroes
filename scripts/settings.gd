extends Node

enum WindowMode {WINDOWED, FULLSCREEN, FRAMELESS}

# Common resolutions (16:9, 16:10, 4:3)
var resolutions = [
	Vector2i(1280, 720),   # HD
	Vector2i(1366, 768),   # HD+
	Vector2i(1600, 900),   # HD+
	Vector2i(1920, 1080),  # Full HD
	Vector2i(2560, 1440),  # QHD
	Vector2i(3840, 2160),  # 4K UHD
	Vector2i(1280, 800),   # 16:10
	Vector2i(1440, 900),   # 16:10
	Vector2i(1680, 1050),  # 16:10
	Vector2i(1920, 1200),  # 16:10
	Vector2i(1024, 768),   # 4:3
	Vector2i(1280, 960),   # 4:3
	Vector2i(1600, 1200)   # 4:3
]

var current_window_mode: int = WindowMode.WINDOWED
var current_resolution_index: int = 0
var window_size: Vector2i = Vector2i(1280, 720)  # Default window size

# Called when the node enters the scene tree for the first time
func _ready():
	load_settings()
	apply_window_settings()

# Apply both window mode and resolution settings
func apply_window_settings():
	# Apply resolution first
	window_size = resolutions[current_resolution_index]
	
	# Then apply window mode with the selected resolution
	match current_window_mode:
		WindowMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(window_size)
			
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
		WindowMode.FRAMELESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(window_size)


# Set window mode and apply changes
func set_window_mode(mode: int):
	current_window_mode = mode
	apply_window_settings()
	save_settings()

# Set resolution by index and apply changes
func set_resolution(index: int):
	if index >= 0 and index < resolutions.size():
		current_resolution_index = index
		apply_window_settings()
		save_settings()

# Get resolution as string for display
func get_resolution_string(index: int) -> String:
	if index >= 0 and index < resolutions.size():
		var res = resolutions[index]
		return str(res.x) + "×" + str(res.y)
	return ""

# Find closest resolution index to a given resolution
func find_closest_resolution(res: Vector2i) -> int:
	var closest_index = 0
	var closest_distance = INF
	
	for i in range(resolutions.size()):
		var distance = (resolutions[i] - res).length_squared()
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i
	
	return closest_index

# Save settings to a config file
func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "window_mode", current_window_mode)
	config.set_value("display", "resolution_index", current_resolution_index)
	config.save("user://settings.cfg")

# Load settings from config file
func load_settings():
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	
	if error == OK:
		current_window_mode = config.get_value("display", "window_mode", WindowMode.WINDOWED)
		current_resolution_index = config.get_value("display", "resolution_index", 0)
	else:
		# If no settings file exists, try to set a sensible default resolution
		var screen_size = DisplayServer.screen_get_size()
		current_resolution_index = find_closest_resolution(screen_size)
		if screen_size.x >= 1920 and screen_size.y >= 1080:
			# Default to 1080p for large screens
			current_resolution_index = 3  # Index of 1920x1080
