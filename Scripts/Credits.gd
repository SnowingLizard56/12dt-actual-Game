extends Control

@export var messages:Array[String]

var message_index = 0
var running_messages = true


func game_over():
	print("Hope You Enjoyed! It's been fun coding and debugging and debugging and debugging and")
	print("ben")
	get_tree().paused = true
	show()
	$MessageVisibilityTimer.start()
	$Message.text = messages[message_index]


func _process(delta):
	if running_messages:
		var timer_ratio = $MessageVisibilityTimer.time_left / $MessageVisibilityTimer.wait_time
		$Message.visible_ratio = 1 - timer_ratio
	else:
		pass


func _on_message_linger_timer_timeout():
	message_index += 1
	if message_index < len(messages):
		$MessageVisibilityTimer.start()
		$Message.text = messages[message_index]
		_process(0)
	else:
		$MessageTransitionTimer.start()
