extends Camera2D

var target_position = Vector2.ZERO
var moving = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !moving: return
	position = lerp(position, target_position, 4*delta)
	if (target_position - position).length() < 4:
		position = target_position
		moving = false
		
