extends Node

signal data_updated

var config = ConfigFile.new()

var time:float = 0
var deaths = 0
var showtimer = true

var start_in_room = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	update_data()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_node_or_null("/root/Main") is Node2D:
		time += delta

func save_config():
	config.set_value("Settings", "showtimer", showtimer)
	for i in ["Jump", "Left", "Right", "Up", "Down"]:
		config.set_value("Settings/Controls", i, InputMap.action_get_events(i))
		
	config.save("user://save.cfg")
	update_data()
	
func save_game():
	config.set_value("SaveData", "time", time)
	config.set_value("SaveData", "room", get_node("/root/Main/LevelConstructor").current_level.level_name)
	config.set_value("SaveData", "deaths", deaths)
	
	config.save("user://save.cfg")
	update_data()

func update_data():
	var _err = config.load("user://save.cfg")
	
	# Save Data
	time = config.get_value("SaveData", "time", 0.0)
	deaths = config.get_value("SaveData", "deaths", 0)
	start_in_room = config.get_value("SaveData", "room", "")
	
	# Settings
	showtimer = config.get_value("Settings", "showtimer", false)
	if config.get_value("Settings/Controls", "Jump"):
		for i in ["Jump", "Left", "Right", "Up", "Down"]:
			InputMap.action_erase_events(i)
			for evnt in config.get_value("Settings/Controls", i):
				InputMap.action_add_event(i, evnt)
	data_updated.emit()

func save_reset():
	config.erase_section("SaveData")
	config.save("user://save.cfg")
