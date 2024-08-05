class_name Entity extends Area2D

@export var size = Vector2.ONE
@export var exists:Array[bool]
@export var entity_type:entities
@export var rotat:int
@export var flag:int = -1

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


func clip_polygon(rect:Rect2):
	stored_polygons = StaticbodyController.clip_polygons_with_rect([get_polygon()], rect, self)


func player_entered(body):
	if body is Player:
		body.entity_collision(self)
