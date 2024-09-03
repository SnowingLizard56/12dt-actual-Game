extends Control

signal pause_exited

@export var timer_button:Button
@export var jump_button:Button
@export var left_button:Button
@export var right_button:Button
@export var down_button:Button
@export var up_button:Button

func _ready():
	update_vis()

func timer_toggled():
	PersistentData.showtimer = !PersistentData.showtimer
	update_vis()

var input_target:String
var waiting_for_input = false
func change_input(input:String):
	if !Input.is_action_just_released("Click"):
		InputMap.action_erase_events(input)
		update_vis()
	else:
		waiting_for_input = true
		input_target = input

func update_vis():
	waiting_for_input = false
	timer_button.text = "Timer: " + ["Off", "On"][int(PersistentData.showtimer)]
	for i in 5:
		var b = [jump_button, left_button, right_button, down_button, up_button][i]
		var t = ["Jump", "Left", "Right", "Down", "Up"][i]
		b.text = t + ": "
		for inp in InputMap.action_get_events(t):
			b.text += inp.as_text().substr(0, inp.as_text().find(" ")) + ", "
		b.text = b.text.substr(0, len(b.text) - 2)

func exit():
	PersistentData.save_config()
	waiting_for_input = false
	pause_exited.emit()

func _input(event):
	if waiting_for_input and event is InputEventKey:
		if event.pressed:
			InputMap.action_add_event(input_target, event)
			update_vis()
		
