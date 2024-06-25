class_name Entity extends Area2D

@export var size = Vector2.ONE
@export var exists:Array[bool]

@onready var initial_position:Vector2 = position

@export var entity_type:entities

enum entities {
	Spike
}

var sprite:Sprite2D

var sprites:Array[Texture2D] = [
	load("res://Graphics/spike.png")
]

var stored_polygons = []

func _ready():	
	add_to_group("Clip_Entity")
	var k = CollisionPolygon2D.new()
	k.polygon = get_polygon()
	add_child(k)
	initial_position = position
	position = Vector2.ZERO
	connect("body_entered", player_entered)
	sprite = Sprite2D.new()
	add_child(sprite)
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.texture = sprites[entity_type]
	sprite.position = initial_position + size/2
	
	
func get_polygon():
	return [
		initial_position, 
		initial_position + Vector2(size.x, 0), 
		initial_position + size, 
		initial_position + Vector2(0, size.y)
		]


func clip_polygon(rect:Rect2):
	stored_polygons = StaticbodyController.clip_polygons_with_rect([get_polygon()], rect, stored_polygons, self)


func player_entered(body):
	if body is Player:
		body.entity_collision(self)
