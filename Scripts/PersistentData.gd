extends Node

signal data_updated

var config = ConfigFile.new()

var time:float = 0
var deaths = 0
var showtimer = true
var volume = 7
var music_volume = 7

var start_in_room = ""


func _ready():
	update_data()


func _process(delta):
	if get_node_or_null("/root/Main") is Node2D:
		time += delta


func save_config():
	# Save settings to config.
	config.set_value("Settings", "showtimer", showtimer)
	config.set_value("Settings", "volume", volume)
	config.set_value("Settings", "music_volume", music_volume)
	for i in ["Jump", "Left", "Right", "Up", "Down"]:
		config.set_value("Settings/Controls", i, InputMap.action_get_events(i))
		
	config.save("user://save.cfg")
	update_data()
	
	
func save_game():
	# Save game state to config file.
	config.set_value("SaveData", "time", time)
	config.set_value("SaveData", "room", 
			get_node("/root/Main/LevelConstructor").current_level.level_name)
	config.set_value("SaveData", "deaths", deaths)
	
	config.save("user://save.cfg")
	update_data()


func update_data():
	# Load Data from config file.
	var _err = config.load("user://save.cfg")
	
	# Save Data
	time = config.get_value("SaveData", "time", 0.0)
	deaths = config.get_value("SaveData", "deaths", 0)
	start_in_room = config.get_value("SaveData", "room", "")
	
	# Settings
	showtimer = config.get_value("Settings", "showtimer", false)
	volume = config.get_value("Settings", "volume", 3)
	music_volume = config.get_value("Settings", "music_volume", 7)
	apply_volume()
	if config.get_value("Settings/Controls", "Jump"):
		for i in ["Jump", "Left", "Right", "Up", "Down"]:
			InputMap.action_erase_events(i)
			for evnt in config.get_value("Settings/Controls", i):
				InputMap.action_add_event(i, evnt)
	data_updated.emit()


func apply_volume():
	# Apply volume variables to respective busses
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(volume / 10.0))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), linear_to_db(music_volume / 10.0))


func save_reset():
	# Delete save
	config.erase_section("SaveData")
	config.save("user://save.cfg")
	update_data()
