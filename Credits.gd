extends Control

@export var messages:Array[String]

var message_index = 0

func game_over():
	print("Hope You Enjoyed! It's been fun coding and debugging and debugging and debugging and")
	print("ben")
	get_tree().paused = true
