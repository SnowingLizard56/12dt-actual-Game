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

var direction: set=update_dir
var last_dir = 1
var stamina = 0
var climb_dir = 0

enum states {Grounded, Climb, Falling}
var state = states.Falling: set=set_state
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func update_dir(d):
	if d != 0:
		last_dir = d
	direction = d

func set_state(n):
	if n == states.Grounded:
		stamina = MAX_STAMINA
	elif n == states.Climb:
		if test_move(transform, Vector2(4, 0)):
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
	
	move_and_slide()


func falling(delta):
	# Gravity
	velocity.y = move_toward(velocity.y, gravity, gravity * delta)
	# Friction
	velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)
	
	# Change states
	if is_on_floor():
		state = states.Grounded
	elif is_on_wall_only():
		state = states.Climb


func grounded(delta):
	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or !$CoyoteTime.is_stopped()):
		velocity.y = JUMP_SPEED
		state = states.Falling
	
	# Change velocity
	velocity.x = direction * SPEED
	
	if !is_on_floor():
		velocity.x = last_dir * SPEED 
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

