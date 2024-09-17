extends Control

@export var screenwipetimer:Timer
@export var quitfadetimer:Timer
@export var screenwipe:Gradient
@export var screenwipenode:Node


func _ready():
	get_node("../ScreenWipe").show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		pause()
	
	if !quitfadetimer.is_stopped():
		screenwipenode.modulate = screenwipe.sample(1-(quitfadetimer.time_left/quitfadetimer.wait_time))
	elif !screenwipetimer.is_stopped():
		screenwipenode.modulate = screenwipe.sample(screenwipetimer.time_left/screenwipetimer.wait_time)
		
func pause():
	visible = true
	get_tree().paused = true

func resume():
	visible = false
	get_tree().paused = false

func quit():
	# save current level etc etc
	PersistentData.save_game()
	get_tree().paused = false
	screenwipenode.show()
	quitfadetimer.start()
	
func quit_finish():
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")


func _on_resume_pressed():
	# made this function by accident but i cant be bothered to change it
	resume()

func hide_wipe():
	if quitfadetimer.is_stopped():
		screenwipenode.hide()
