class_name Player extends CharacterBody2D

const SPEED = 150.0
const SLOW_SPEED = 75.0
const JUMP_SPEED_HORIZONTAL = 200
const AIR_MOVE_SPEED = 250.0
const CLIMB_SPEED = 120.0
const JUMP_SPEED = -300.0
const CLIMB_FINISH_SPEED = 50.0
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
var real_position:Vector2
var jumping = false

@onready var spawn_position: Vector2 = position

signal screen_exited

enum states {Grounded, Climb, Falling}
var state = states.Falling: set=set_state

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
	if $"../ActiveLevelFollower".moving: return
	crush_check()
	if real_position:
		position = real_position
	direction = Input.get_axis("Left", "Right")
	if Input.is_action_just_pressed("Jump") or $JumpBuffer.time_left > 0:
		jumping = true
	else:
		jumping = false
	if state == states.Grounded or (jumping and !$CoyoteTimer.is_stopped()):
		grounded(delta)
	elif state == states.Falling:
		falling(delta)
	elif state == states.Climb:
		climb(delta)
	move_and_slide()
	real_position = position
	position = round(position)


# Physics States
func falling(delta):
	# Gravity
	velocity.y = move_toward(velocity.y, GRAVITY/2, GRAVITY * delta)
	# Friction
	velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)
	
	
	velocity.x = lerp(velocity.x, direction * SPEED, delta*6)
	
	if Input.is_action_just_pressed("Jump"):
		$JumpBuffer.start()
	
	if is_on_ceiling():
		velocity.y = CEILING_BOUNCE_SPEED
	# Change statesd a
	if is_on_floor():
		state = states.Grounded
	elif test_move(transform, Vector2.RIGHT*last_dir):
		state = states.Climb


func grounded(delta):
	# Handle Jump.
	if jumping and (is_on_floor() or !$CoyoteTimer.is_stopped()):
		velocity.y = JUMP_SPEED
		state = states.Falling
	
	# Change velocity
	if Input.is_action_pressed("Down"):
		velocity.x = lerp(velocity.x, direction * SLOW_SPEED, delta*30)
	else:
		velocity.x = lerp(velocity.x, direction * SPEED, delta*30)
	if abs(velocity.x) < 1.5:
		velocity.x = 0
	
	if !is_on_floor():
		state = states.Falling
		$CoyoteTimer.start()
	elif test_move(transform, Vector2.RIGHT * direction) and Input.is_action_pressed("Up"):
		state = states.Climb
		velocity += Vector2.UP * 4


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
	if jumping:
		state = states.Falling
		if direction:
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= -climb_dir
		else:
			velocity.x = -climb_dir * WALL_DROP_SPEED
	
	# Leaving state
	elif !test_move(transform, Vector2.RIGHT * climb_dir):
		state = states.Falling
		if direction == 0 and vdirection < 0:
			velocity.x = CLIMB_FINISH_SPEED * climb_dir
		else:
			velocity.x = CLIMB_FINISH_SPEED * direction
			if vdirection < 0:
				stamina -= 40
			if vdirection > 0 and direction:
				velocity.y *= 0.5
	elif is_on_floor():
		state = states.Grounded

# Change Overlapping Windows
func on_window_entered(window):
	overlapping_windows.append(window)

func on_window_exited(window):
	overlapping_windows.erase(window)

func death():
	real_position = spawn_position
	velocity = Vector2.ZERO
	state = states.Falling
	get_node("../LevelConstructor").allow_switch = true

func entity_collision(ent):
	if ent.entity_type == Entity.entities.Spike:
		death()

func crush_check():
	for i in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		if !test_move(transform.translated(i*2), Vector2.ZERO):
			return false
	death()
	return true

func _on_visible_notifier_screen_exited():
	screen_exited.emit()
