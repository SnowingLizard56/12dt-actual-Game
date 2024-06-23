@tool
class_name Entity extends Area2D

@export var size = Vector2.ONE
@export var exists:Array[bool]

@onready var initial_position:Vector2 = position

enum entities {
	Spike
}

var stored_polygons = []

func _ready():
	if Engine.is_editor_hint():
		add_to_group("Clip_Entity")
		for i in entities:
			if has_meta(str(i)):
				continue
			set_meta(str(i), false)
	else:
		var k = CollisionPolygon2D.new()
		k.polygon = get_polygon()
		add_child(k)
		initial_position = position
		position = Vector2.ZERO
		connect("body_entered", player_entered)

	
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
