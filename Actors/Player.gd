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
		if test_move(transform, Vector2(4, 0)):
			climb_dir = 1
		else:
			climb_dir = -1
	state = n


func _physics_process(delta):
	direction = Input.get_axis("Left", "Right")
	if state == states.Grounded or (Input.is_action_just_pressed("Jump") and !$CoyoteTimer.is_stopped()):
		grounded(delta)
	elif state == states.Falling:
		falling(delta)
	elif state == states.Climb:
		climb(delta)
	move_and_slide()
			

# Physics States
func falling(delta):
	# Gravity
	velocity.y = move_toward(velocity.y, GRAVITY, GRAVITY * delta)
	# Friction
	velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)
	
	if is_on_ceiling():
		velocity.y = CEILING_BOUNCE_SPEED
	# Change states
	if is_on_floor():
		state = states.Grounded
	elif is_on_wall():
		state = states.Climb


func grounded(_delta):
	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or !$CoyoteTimer.is_stopped()):
		velocity.y = JUMP_SPEED
		state = states.Falling
	
	# Change velocity
	velocity.x = direction * SPEED
	
	if !is_on_floor():
		state = states.Falling
		$CoyoteTimer.start()


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
	elif !is_on_wall():
		state = states.Falling
		if direction == 0 and vdirection < 0:
			velocity.x = CLIMB_FINISH_SPEED * climb_dir
		else:
			velocity.x = CLIMB_FINISH_SPEED * direction
			if vdirection < 0:
				stamina -= 40
			if vdirection > 0 and direction:
				velocity.y *= 0.5

# Change Overlapping Windows
func on_window_entered(window):
	overlapping_windows.append(window)


func on_window_exited(window):
	overlapping_windows.erase(window)
