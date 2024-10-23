extends Control

signal pause_exited
signal any_button_pressed

@export var timer_button:Button
@export var volume_button:Button
@export var jump_button:Button
@export var left_button:Button
@export var right_button:Button
@export var down_button:Button
@export var up_button:Button
@export var volume2_button:Button

var save_reset_countdown = 5
var input_target:String
var waiting_for_input = false


func _ready():
	update_vis()


func timer_toggled():
	PersistentData.showtimer = !PersistentData.showtimer
	update_vis()


func change_input(input:String):
	if !Input.is_action_just_pressed("Click"):
		# Clear inputs
		InputMap.action_erase_events(input)
		update_vis()
	else:
		# Wait for input
		waiting_for_input = true
		input_target = input


func update_vis():
	waiting_for_input = false
	# Specific (timer, volumes)
	timer_button.text = "Timer: " + ["Off", "On"][int(PersistentData.showtimer)]
	volume_button.text = "SFX: " + str(PersistentData.volume)
	volume2_button.text = "MUSIC: " + str(PersistentData.music_volume)
	# Generaliseable (Controls)
	for i in 5:
		var b = [jump_button, left_button, right_button, down_button, up_button][i]
		var t = ["Jump", "Left", "Right", "Down", "Up"][i]
		b.text = t + ": "
		for inp in InputMap.action_get_events(t):
			# Find the substring that contains the name of the key: 
			# From the start to the first space.
			b.text += inp.as_text().substr(0, inp.as_text().find(" ")) + ", "
		b.text = b.text.substr(0, len(b.text) - 2)
	

func exit():
	# Return to main menu
	PersistentData.save_config()
	waiting_for_input = false
	pause_exited.emit()


func _input(event):
	# Detect all input for changing controls
	if waiting_for_input and event is InputEventKey:
		if event.pressed:
			InputMap.action_add_event(input_target, event)
			update_vis()


func button_press():
	# Link to sfx
	any_button_pressed.emit()


func reset_save():
	if save_reset_countdown == 0:
		# Continue with save reset
		PersistentData.save_reset()
		get_tree().reload_current_scene()
	else:
		$Clear.text = "Are you sure? (" + str(save_reset_countdown) + ")"
		save_reset_countdown -= 1


func volume_change(type:String):
	# Type = "sfx" or "mus"
	# Increment / decrement
	if Input.is_action_just_pressed("Click"):
		if type == "sfx":
			PersistentData.volume += 1
		else:
			PersistentData.music_volume += 1
	else:
		if type == "sfx":
			PersistentData.volume -= 1
		else:
			PersistentData.music_volume -= 1
	# Wrap
	if PersistentData.volume > 10:
		PersistentData.volume = 0
	elif PersistentData.volume < 0:
		PersistentData.volume = 10
	
	if PersistentData.music_volume > 10:
		PersistentData.music_volume = 0
	elif PersistentData.music_volume < 0:
		PersistentData.music_volume = 10
	
	PersistentData.apply_volume()
	# Display
	update_vis()
