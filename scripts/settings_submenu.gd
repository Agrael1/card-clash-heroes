extends VBoxContainer

@onready var window_mode_option : OptionButton = $VBoxContainer/WindowModeHBox/ItemList
@onready var resolution_option : OptionButton = $VBoxContainer/ResolutionHBox/ItemList

var disabled_indices = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Windowed")
	window_mode_option.add_item("Fullscreen")
	window_mode_option.add_item("Frameless")
	window_mode_option.select(Settings.current_window_mode)
	
	_setup_resolution_dropdown()
	
	resolution_option.item_selected.connect(_on_resolution_selected)
	window_mode_option.item_selected.connect(_on_window_mode_selected)


func _setup_resolution_dropdown():
	resolution_option.clear()
	disabled_indices.clear()
	
	# Add 16:9 category header
	resolution_option.add_item("--- 16:9 ---")
	resolution_option.set_item_disabled(0, true)
	disabled_indices.append(0)
	
	# Add 16:9 resolutions
	var item_index = 1
	for i in range(Settings.resolutions.size()):
		var res = Settings.resolutions[i]
		if abs(float(res.x) / res.y - 16.0 / 9.0) < 0.01:
			resolution_option.add_item(Settings.get_resolution_string(i))
			item_index += 1
	
	# Add 16:10 category header
	resolution_option.add_item("--- 16:10 ---")
	resolution_option.set_item_disabled(item_index, true)
	disabled_indices.append(item_index)
	item_index += 1
	
	# Add 16:10 resolutions
	for i in range(Settings.resolutions.size()):
		var res = Settings.resolutions[i]
		if abs(float(res.x) / res.y - 16.0 / 10.0) < 0.01:
			resolution_option.add_item(Settings.get_resolution_string(i))
			item_index += 1
	
	# Add 4:3 category header
	resolution_option.add_item("--- 4:3 ---")
	resolution_option.set_item_disabled(item_index, true)
	disabled_indices.append(item_index)
	item_index += 1
	
	# Add 4:3 resolutions
	for i in range(Settings.resolutions.size()):
		var res = Settings.resolutions[i]
		if abs(float(res.x) / res.y - 4.0 / 3.0) < 0.01:
			resolution_option.add_item(Settings.get_resolution_string(i))
			item_index += 1
	
	# Select the current resolution
	select_current_resolution()

# Convert from resolution index to UI index
func resolution_index_to_ui_index(resolution_index):
	var ui_index = 0
	var found_resolutions = 0
	
	for i in range(resolution_option.item_count):
		if i in disabled_indices:
			continue
			
		# This is a valid resolution item
		if found_resolutions == resolution_index:
			return i
			
		found_resolutions += 1
	
	return -1  # Not found

# Convert from UI index to resolution index
func ui_index_to_resolution_index(ui_index):
	var resolution_index = 0
	
	for i in range(ui_index):
		if i in disabled_indices:
			continue
		resolution_index += 1
	
	return resolution_index

# Select the current resolution in the dropdown
func select_current_resolution():
	var ui_index = resolution_index_to_ui_index(Settings.current_resolution_index)
	if ui_index >= 0:
		resolution_option.selected = ui_index

func _on_window_mode_selected(index):
	Settings.set_window_mode(index)

func _on_resolution_selected(index):
	# Skip if a disabled item was somehow selected
	if index in disabled_indices:
		return
		
	# Convert UI index to resolution index
	var resolution_index = 0
	for i in range(index):
		if i not in disabled_indices:
			resolution_index += 1
			
	Settings.set_resolution(resolution_index)
