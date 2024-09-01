extends Node

var config = ConfigFile.new()

var time:float = 0
var deaths = 0
var showtimer = true

var start_in_room = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var err = config.load("user://save.cfg")
	
	# Save Data
	time = config.get_value("SaveData", "time", 0.0)
	deaths = config.get_value("SaveData", "deaths", 0)
	deaths = config.get_value("SaveData", "room", "")
	
	# Settings
	showtimer = config.get_value("Settings", "showtimer", showtimer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_node_or_null("/root/Main") is Node2D:
		time += delta

func save_config():
	config.set_value("Settings", "showtimer", showtimer)
	
func save_game():
	config.set_value("SaveData", "time", time)
	config.set_value("SaveData", "room", get_node_or_null("/root/Main/LevelConstructor").current_level.level_name)
	config.set_value("SaveData", "deaths", deaths)
