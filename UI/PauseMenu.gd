extends Control

@export var screenwipetimer:Timer
@export var screenwipe:Gradient
@export var screenwipenode:Node

func _ready():
	get_node("../ScreenWipe").show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		pause()
	
	if !screenwipetimer.is_stopped():
		screenwipenode.modulate = screenwipe.sample(screenwipetimer.time_left/screenwipetimer.wait_time)
		
func pause():
	visible = !visible
	get_tree().paused = !get_tree().paused

func quit():
	# save current level etc etc
	get_node("/root/PersistentData").save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
