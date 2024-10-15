class_name Player extends CharacterBody2D

const SPEED = 120.0
const SLOW_SPEED = 50.0
const JUMP_SPEED_HORIZONTAL = 200
const AIR_MOVE_SPEED = 250.0
const CLIMB_SPEED = 70.0
const JUMP_SPEED = -300.0
const CLIMB_FINISH_SPEED = 120.0
const MAX_STAMINA = 350.0
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

var ascend_lock = false
var check_trans:Transform2D

var falling_down = false


# Variable set functions
func update_dir(d):
	if d != 0:
		last_dir = d
	direction = d


func set_state(n):
	var continue_set = true
	if n == states.Grounded:
		stamina = MAX_STAMINA
		velocity.y = 0
	elif n == states.Climb:
		climb_dir = direction
		$Sprite.scale.x = abs($Sprite.scale.x) * climb_dir
	elif n == states.Falling:
		falling_down = false
	if continue_set:
		state = n


func _physics_process(delta):
	# Skip if respawning
	if !$RespawnTimer.is_stopped(): return
	# Skip if screen transition
	if $"/root/Main/ActiveLevelFollower".moving: return
	# Get from pixel
	if real_position:
		position = real_position
	# Detect direction
	if !$LockDirectionTimer.is_stopped():
		direction = locked_direction
	else:
		direction = Input.get_axis("Left", "Right")
	# Sprite direction
	if direction != 0 and state != states.Climb:
		$Sprite.scale.x = abs($Sprite.scale.x) * direction
	# Detect jump
	if Input.is_action_just_pressed("Jump") or $JumpBuffer.time_left > 0:
		jumping = true
	else:
		jumping = false
	# State machine
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
	# Keep on sides of screen
	var current_level = get_node("../LevelConstructor").current_level
	if position.x > current_level.offset.x + 632:
		if current_level.data["Connections"][3] == "": 
			position.x = current_level.offset.x + 632
			velocity.x = 0
	elif position.x < current_level.offset.x + 8:
		if current_level.data["Connections"][2] == "":
			position.x = current_level.offset.x + 8
			velocity.x = 0
	if position.y < current_level.offset.y + 19 :
		if current_level.data["Connections"][0] == "": 
			position.y = current_level.offset.y + 19
			if velocity.y < 0:
				velocity.y = 0
		
	# Return to pixel
	real_position = position
	position = round(position)


func _process(delta):
	if !$RespawnTimer.is_stopped():
		$Sprite.modulate = respawn_gradient.sample(1-($RespawnTimer.time_left/$RespawnTimer.wait_time))


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
	# Change states
	if is_on_floor() and velocity.y >= 0:
		$Sprite.play("Fall_Landing")
		state = states.Grounded
	else:
		var t = transform
		var m = Vector2(abs(velocity.x)/velocity.x, 0)
		if test_move(t, m) and !(!test_move(t.translated(Vector2(0, -10)), m) or !test_move(t.translated(Vector2(0, 11)), m)):
			direction = abs(velocity.x)/velocity.x
			state = states.Climb


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
		velocity = Vector2.UP*4


func climb(delta):
	var vdirection = Input.get_axis("Up", "Down")
	
	# No stamina? Fall.
	if stamina < 0 and vdirection <= 0:
		vdirection = 0.5
	elif vdirection > 0:
		vdirection = 1.5
	# Check 11 pixels up for idle. if not on wall 11 pixels up, then fall down a bit.
	if !ascend_lock:
		check_trans = transform.translated(Vector2(0, -10))
	
	if !test_move(check_trans, Vector2.RIGHT * climb_dir):
		if vdirection < 0 or ascend_lock:
			ascend_lock = true
		else:
			vdirection = 1
	elif ascend_lock:
		ascend_lock = false
	
	# Check 11 pixels down. if not on wall, force fall.
	if !test_move(transform.translated(Vector2(0, 11)), Vector2.RIGHT * climb_dir):
		if vdirection > 0:
			state = states.Falling
			return
		
	# Change Stamina
	if vdirection < 0:
		stamina -= 100 * delta
	elif vdirection == 0:
		stamina -= 10 * delta
	
	if ascend_lock:
		vdirection = -1
		
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
	elif !test_move(transform, Vector2(climb_dir, 0)):
		state = states.Falling
		ascend_lock = false
		if vdirection < 0 or ascend_lock:
			velocity.x = CLIMB_FINISH_SPEED * climb_dir
			$Sprite.play("Jump")
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
	$Sprite.scale.x = 1
	state = states.Falling
	crushed = false
	get_node("/root/PersistentData").deaths += 1
	
	
func entity_collision(ent):
	if ent.entity_type == Entity.entities.Spike:
		death()


func crush_check():
	for i in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		if !test_move(transform.translated(i*2), Vector2.ZERO):
			position += i*2
			return false
	crushed = true
	death()
	return true


func _on_visible_notifier_screen_exited():
	if visible:
		screen_exited.emit()


func _on_sprite_animation_finished():
	if state == states.Falling and $Sprite.animation != "Jump":
		$Sprite.play("Fall_Loop")
