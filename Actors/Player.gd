extends CharacterBody2D

const SPEED = 150.0
const JUMP_SPEED_HORIZONTAL = 200
const AIR_MOVE_SPEED = 250.0
const CLIMB_SPEED = 120.0
const JUMP_SPEED = -300.0
const CLIMB_FINISH_SPEED = 100.0
const MAX_STAMINA = 100.0
const AIR_FRICTION = 25.0
const WALL_JUMP_VELOCITY = Vector2(200.0, -280.0)
const WALL_DROP_SPEED = 60.0
const GRAVITY = 980
const CEILING_BOUNCE_SPEED = 2

var direction: set=update_dir
var last_dir = 1
var stamina = 0
var climb_dir = 0
var overlapping_windows = []
var overlapping_inner = false

enum states {Grounded, Climb, Falling}
var state = states.Falling: set=set_state

var global:globalScript

func _ready():
	global = get_node("/root/Global")
	global.player = self

# variable set functions
func update_dir(d):
	if d != 0:
		last_dir = d
	direction = d

func set_state(n):
	if n == states.Grounded:
		stamina = MAX_STAMINA
		velocity.y = 0
	elif n == states.Climb:
		if physics_check_all_playerboxes("test_move", [transform, Vector2(4, 0)]):
			climb_dir = 1
		else:
			climb_dir = -1
	state = n


func _physics_process(delta):
	direction = Input.get_axis("Left", "Right")
	if state == states.Grounded or (Input.is_action_just_pressed("Jump") and !$CoyoteTime.is_stopped()):
		grounded(delta)
	elif state == states.Falling:
		falling(delta)
	elif state == states.Climb:
		climb(delta)
	# eveybody else :)
	for player_stand_in in global.playerboxes:
		player_stand_in.position = position
		player_stand_in.velocity = velocity
		player_stand_in.move_and_slide()
	# check for really goofy collision
	if len(overlapping_windows) == 1:
		if overlapping_inner:
			# entirely within window
			pass
		else:
			# area 2! between inner and outer borders
			pass
		position = overlapping_windows[0].player_box.position
	elif len(overlapping_windows) == 0:
		# entirely outside of window
		move_and_slide()
	else:
		# or in both windows at once.
		# if playerbox 0 is moving slower than playerbox 1, 
		# then it has collided with something. set to that position.
		if overlapping_windows[0].player_box.velocity.length()\
			<= overlapping_windows[1].player_box.velocity.length():
			position = overlapping_windows[0].player_box.position
		else:
			#otherwise, set to the other one.
			position = overlapping_windows[1].player_box.position
			

# Physics States
func falling(delta):
	# Gravity
	velocity.y = move_toward(velocity.y, GRAVITY, GRAVITY * delta)
	# Friction
	velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)
	
	if check_on_ceiling():
		velocity.y = CEILING_BOUNCE_SPEED
	# Change states
	if check_on_floor():
		state = states.Grounded
	elif check_on_wall():
		state = states.Climb


func grounded(delta):
	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and (check_on_floor() or !$CoyoteTime.is_stopped()):
		velocity.y = JUMP_SPEED
		state = states.Falling
	
	# Change velocity
	velocity.x = direction * SPEED
	
	if !check_on_floor():
		state = states.Falling
		$CoyoteTime.start()


func climb(delta):
	var vdirection = Input.get_axis("Up", "Down")
	# No stamina? Fall.
	if stamina < 0 and vdirection <= 0:
		vdirection = 0.5
	elif vdirection > 0:
		vdirection = 1.5
		
	
	# Change Stamina
	if vdirection < 0:
		stamina -= 40 * delta
	elif vdirection == 0:
		stamina -= 25 * delta
	
	velocity.y = vdirection * CLIMB_SPEED
	
	# Wall Jump!
	if Input.is_action_just_pressed("Jump"):
		state = states.Falling
		if direction:
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= -climb_dir
		else:
			velocity.x = -climb_dir * WALL_DROP_SPEED
	
	# Leaving state
	elif !check_on_wall():
		state = states.Falling
		if direction == 0 and vdirection < 0:
			velocity.x = CLIMB_FINISH_SPEED * climb_dir
		else:
			velocity.x = CLIMB_FINISH_SPEED * direction
			if vdirection < 0:
				stamina -= 40
			if vdirection > 0 and direction:
				velocity.y *= 0.5


# Physics functions
func check_on_floor():
	return physics_check_all_playerboxes("is_on_floor", [])


func check_on_wall():
	return physics_check_all_playerboxes("is_on_wall", [])


func check_on_ceiling():
	return physics_check_all_playerboxes("is_on_ceiling", [])


func physics_check_all_playerboxes(stringName, args):
	if len(overlapping_windows) == 0:
		for w in global.playerboxes:
			if w.callv(stringName, args):
				return true
	else:
		for w in overlapping_windows:
			if w.player_box.callv(stringName, args):
				return true
	return false


# Change Overlapping Windows
func on_window_entered(window):
	overlapping_windows.append(window)


func on_window_exited(window):
	overlapping_windows.erase(window)
