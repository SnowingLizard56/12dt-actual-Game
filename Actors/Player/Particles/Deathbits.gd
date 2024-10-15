extends Node2D

@export var bodyparts:Array[RigidBody2D]
@export var gradient:Gradient


func start(playerScale, velocity):
	for i in bodyparts:
		i.scale = playerScale
		i.linear_velocity = velocity
		i.linear_velocity += Vector2(randf_range(-1, 1), 0) * 50


func _process(delta):
	# modulate
	modulate = gradient.sample(1.0 - ( $LastingTimer.time_left / $LastingTimer.wait_time))
