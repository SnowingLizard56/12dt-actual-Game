extends Control

@export var messages:Array[String]

var message_index = 0
var running_messages = true
var showing_credits = false


# Called when player hits the dimensional stabiliser
func game_over():
	print("Hope You Enjoyed! It's been fun coding and debugging and debugging and debugging and")
	print("ben") # D:
	get_tree().paused = true
	show()
	$MessageVisibilityTimer.start()
	$Message.text = messages[message_index]


func _process(delta):
	if running_messages: 
		# Letter-by-letter message visibility
		var timer_ratio = $MessageVisibilityTimer.time_left / $MessageVisibilityTimer.wait_time
		$Message.visible_ratio = 1 - timer_ratio
	elif showing_credits:
		# Credits fade in
		var timer_ratio = $MessageTransitionTimer.time_left / $MessageTransitionTimer.wait_time
		$Credits.modulate = Color(1, 1, 1, 1 - timer_ratio)
		if Input.is_action_just_pressed("Skip"):
			print("Confused")
			get_node("../PauseMenu").quit_finish()
	else:
		# Message fade out
		var timer_ratio = $MessageTransitionTimer.time_left / $MessageTransitionTimer.wait_time
		$Message.modulate = Color(1, 1, 1, timer_ratio)


func _on_message_linger_timer_timeout():
	# Go to next message
	message_index += 1
	if message_index < len(messages):
		$MessageVisibilityTimer.start()
		$Message.text = messages[message_index]
		_process(0)
	else:
		running_messages = false
		$MessageTransitionTimer.start()


func _on_message_transition_timer_timeout():
	if showing_credits:
		# Skip
		return
	elif !running_messages:
		# Wait a little bit
		$StayOnBlackTimer.start()


func start_credits():
	$MessageTransitionTimer.wait_time = 4
	showing_credits = true
	$MessageTransitionTimer.start()
	$Credits.show()
	_process(0)
