class_name Entity extends Area2D

@export var size = Vector2.ONE
@export var exists:Array[bool]
@export var entity_type:entities
@export var rotat:int
@export var flag:int = -1
@export var invert_flag:bool = false

var initial_position:Vector2

enum entities {
	Spike
}

var sprite:Sprite2D


var sprites:Array[Texture2D] = [
	load("res://Graphics/Entity_Graphics/spike.png")
]

var outlines:Array[Texture2D] = [
	load("res://Graphics/Entity_Graphics/Outlines/spike.png")
]

var stored_polygons = []

var window_copies = []

func initialize():
	initial_position = position
	position = Vector2.ZERO
	add_to_group("Clip_Entity")
	var k = CollisionPolygon2D.new()
	k.polygon = get_polygon()
	call_deferred("add_child", k)
	connect("body_entered", player_entered)
	sprite = Sprite2D.new()
	add_child(sprite)
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.texture = sprites[entity_type]
	sprite.position = initial_position
	sprite.centered = false
	sprite.rotation_degrees = rotat
	
	
func switch_to_outline():
	sprite.texture = outlines[entity_type]
	show()


func get_polygon():
	var out = [
		initial_position, 
		initial_position + Vector2(size.x, 0), 
		initial_position + size, 
		initial_position + Vector2(0, size.y)
		]
	if rotat != 0:
		out = StaticbodyController.rotate_polygon(out, initial_position, rotat)
	return out

func reset_polygon():
	stored_polygons = [get_polygon()]

func clip_polygon(rect:Rect2):
	stored_polygons = StaticbodyController.clip_polygons_with_rect(stored_polygons, rect)

func apply_polygons():
	StaticbodyController.add_polygons_as_children(stored_polygons, self)

# Player Collision Stuff!
func player_entered(body):
	if body is Player:
		body.entity_collision(self)


# Flag Stuff!
var prev_offset
var target_offset
var timer:SceneTreeTimer
const SPIKE_OFFSET_DISTANCE = 3
const SPIKE_MOVE_TIME = 0.1


func activate():
	if flag > -1:
		FlagManager.on_flag(flag, flag_on(), invert_flag)
		FlagManager.on_flag(flag, flag_off(), !invert_flag)
		if invert_flag:
			flag_on()
			position = target_offset
			timer = null


func flag_on():
	if entity_type == entities.Spike:
		prev_offset = target_offset
		target_offset += Vector2(0, SPIKE_OFFSET_DISTANCE).rotated(deg_to_rad(rotat))
		timer = get_tree().create_timer(SPIKE_MOVE_TIME)
		monitoring = false
		monitorable = false


func flag_off():
	if entity_type == entities.Spike:
		prev_offset = target_offset
		target_offset -= Vector2(0, SPIKE_OFFSET_DISTANCE).rotated(deg_to_rad(rotat))
		timer = get_tree().create_timer(SPIKE_MOVE_TIME)
		monitoring = true
		monitorable = true


func _process(delta):
	if timer and entity_type == entities.Spike:
		position = lerp(prev_offset, target_offset, (SPIKE_MOVE_TIME - timer.time_left)/SPIKE_MOVE_TIME)
