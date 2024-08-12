class_name Player extends CharacterBody2D

const SPEED = 120.0
const SLOW_SPEED = 50.0
const JUMP_SPEED_HORIZONTAL = 200
const AIR_MOVE_SPEED = 250.0
const CLIMB_SPEED = 70.0
const JUMP_SPEED = -300.0
const CLIMB_FINISH_SPEED = 120.0
const MAX_STAMINA = 300.0
const AIR_FRICTION = 25.0
const WALL_JUMP_VELOCITY = Vector2(200.0, -280.0)
const WALL_DROP_SPEED = 60.0
const GRAVITY = 980
const TERMINAL_VELOCITY = 350

var direction: set=update_dir
var last_dir = 1
var stamina = MAX_STAMINA
var climb_dir = 0
var real_position:Vector2
var jumping = false
var crushed = false

var locked_direction

@onready var spawn_position: Vector2 = position

signal screen_exited

enum states {Grounded, Climb, Falling}
var state = states.Falling: set=set_state

enum particle {DeathNormal, DeathCrushed}
@export var particle_scenes:Array[PackedScene] = []
@export var respawn_gradient:Gradient
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
		$Sprite.scale.x = abs($Sprite.scale.x) * climb_dir
	elif n == states.Falling:
		falling_down = false
	state = n

func _physics_process(delta):
	# skip if respawning
	if !$RespawnTimer.is_stopped(): return
	# skip if screen transition
	if $"../ActiveLevelFollower".moving: return
	#get from pixel
	if real_position:
		position = real_position
	# detect direction
	if !$LockDirectionTimer.is_stopped():
		direction = locked_direction
	else:
		direction = Input.get_axis("Left", "Right")
	# sprite direction
	if direction != 0 and state != states.Climb:
		$Sprite.scale.x = abs($Sprite.scale.x) * direction
	# detect jump
	if Input.is_action_just_pressed("Jump") or $JumpBuffer.time_left > 0:
		jumping = true
	else:
		jumping = false
	# state machine
	if state == states.Grounded or (jumping and !$CoyoteTimer.is_stopped()):
		grounded(delta)
	elif state == states.Falling:
		falling(delta)
	elif state == states.Climb:
		climb(delta)
	if test_move(transform, Vector2.ZERO):
		crush_check()
	else:
		move_and_slide()
	# keep on sides of screen
	var current_level = get_node("../LevelConstructor").current_level
	if position.x > current_level.offset.x + 632:
		if current_level.data["Connections"][3] == "": 
			position.x = current_level.offset.x + 632
			velocity.x = 0
	elif position.x < current_level.offset.x + 8:
		if current_level.data["Connections"][2] == "":
			position.x = current_level.offset.x + 8
			velocity.x = 0
	# return to pixel
	real_position = position
	position = round(position)

func _process(delta):
	if !$RespawnTimer.is_stopped():
		$Sprite.modulate = respawn_gradient.sample(1-($RespawnTimer.time_left/$RespawnTimer.wait_time))

var falling_down = false

# Physics States
func falling(delta):
	# Gravity
	velocity.y = move_toward(velocity.y, TERMINAL_VELOCITY, GRAVITY * delta)
	# Friction
	velocity.x = move_toward(velocity.x, 0, AIR_FRICTION * delta)
	
	velocity.x = lerp(velocity.x, direction * SPEED, delta*6)
	
	# Anims
	if velocity.y > 0 and !falling_down:
		falling_down = true
		$Sprite.play("Fall_Start")
	
	if Input.is_action_just_pressed("Jump"):
		$JumpBuffer.start()
	# Change statesd a
	if is_on_floor():
		$Sprite.play("Fall_Landing")
		state = states.Grounded
	elif test_move(transform, Vector2(abs(velocity.x)/velocity.x, 0)):
			state = states.Climb
			direction = abs(velocity.x)/velocity.x


func grounded(delta):
	# Handle Jump.
	if jumping:
		velocity.y = JUMP_SPEED
		state = states.Falling
		$Sprite.play("Jump")
	
	if direction == 0 and !jumping:
		$Sprite.play("Idle")
	
	# Change velocity
	if Input.is_action_pressed("Down"):
		velocity.x = lerp(velocity.x, direction * SLOW_SPEED, delta*30)
		if direction != 0 and !jumping: $Sprite.play("Walk")
	else:
		velocity.x = lerp(velocity.x, direction * SPEED, delta*30)
		if direction != 0 and !jumping: $Sprite.play("Walk", 2.0)
	if abs(velocity.x) < 1.5:
		velocity.x = 0
	
	if !is_on_floor() and !jumping:
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
	# check 11 pixels up for idle. if not on wall 11 pixels up, then fall down a bit.
	if vdirection >= 0:
		if !test_move(transform.translated(Vector2(0, -10)), Vector2.RIGHT * climb_dir):
			vdirection = 1
		
	# Change Stamina
	if vdirection < 0:
		stamina -= 75 * delta
	elif vdirection == 0:
		stamina -= 25 * delta
	
	velocity.y = vdirection * CLIMB_SPEED
	
	if velocity.y > 0:
		if vdirection != 1:
			$Sprite.play("Climb_Down")
	elif  velocity.y < 0:
		$Sprite.play("Climb_Up")
	else:
		$Sprite.play("Climb_Idle")
	
	# Wall Jump!
	if jumping:
		state = states.Falling
		if vdirection > 0:
			velocity = Vector2(WALL_DROP_SPEED, 0)
		else:
			velocity = WALL_JUMP_VELOCITY
			locked_direction = -climb_dir
			$LockDirectionTimer.start()
			$Sprite.play("Jump")
		velocity.x *= -climb_dir
	
	# Leaving state
	elif !test_move(transform, Vector2.RIGHT * climb_dir):
		state = states.Falling
		if direction == 0 and vdirection < 0:
			velocity.x = CLIMB_FINISH_SPEED * climb_dir
			$Sprite.play("Jump")
		else:
			velocity.x = CLIMB_FINISH_SPEED * direction
			if vdirection < 0:
				stamina -= 40
			if vdirection > 0 and direction:
				velocity.y *= 0.5
	elif is_on_floor():
		state = states.Grounded


func death():
	var k
	if crushed:
		k = particle_scenes[particle.DeathCrushed].instantiate()
	else:
		k = particle_scenes[particle.DeathNormal].instantiate()
		k.call_deferred("start", $Sprite.scale, velocity)
	get_parent().call_deferred("add_child", k)
	k.position += position
	real_position = spawn_position
	position = spawn_position
	velocity = Vector2.ZERO
	$RespawnTimer.start()
	$Sprite.play("Idle")
	state = states.Falling
	crushed = false
	
func entity_collision(ent):
	if ent.entity_type == Entity.entities.Spike:
		if ent.rotat == 0 and velocity.y >= 0:
			death()
		elif ent.rotat == 90 and velocity.x <= 0:
			death()
		elif ent.rotat == 270 and velocity.x >= 0:
			death()
		elif ent.rotat == 180 and velocity.y <= 0:
			death()

func crush_check():
	for i in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		if !test_move(transform.translated(i*2), Vector2.ZERO):
			return false
	crushed = true
	death()
	return true

func _on_visible_notifier_screen_exited():
	if visible:
		screen_exited.emit()


func _on_sprite_animation_finished():
	if state == states.Falling:
		$Sprite.play("Fall_Loop")
