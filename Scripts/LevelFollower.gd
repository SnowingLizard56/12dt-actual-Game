extends Node2D

@export var constructor:LevelConstructor
@export var cam:Camera2D
@export var player:Player

signal target_met

var target_position = Vector2.ZERO:set=set_target
var prev_position = Vector2.ZERO
var moving = false


func set_target(v):
	# Start timer, store  position. 
	$CameraMoveTimer.start()
	prev_position = target_position
	position = v
	target_position = v
	player.get_node("Sprite").pause()
	

func _ready():
	target_met.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !moving: return
	var ratio = (($CameraMoveTimer.wait_time - $CameraMoveTimer.time_left) 
			/ $CameraMoveTimer.wait_time)
	# Go from linear to ease
	ratio = ease(ratio, -5)
	# And feed the ease as the wieght.
	cam.position = lerp(prev_position, target_position, ratio)
	# If "Close Enough"
	if (target_position - cam.position).length() < 1:
		# Done
		cam.position = target_position
		moving = false
		target_met.emit()
		player.get_node("Sprite").play()
