extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Pause"):
		pause()

func pause():
	visible = !visible
	get_tree().paused = !get_tree().paused

func quit():
	# save current level etc etc
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
