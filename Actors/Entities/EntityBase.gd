class_name Entity extends Area2D

@export var size = Vector2.ONE
@export var exists:Array[bool]
@export var entity_type:entities
@export var rotat:int
@export var flag:int = -1
@export var invert_flag:bool = false

var sub_sprites = []

var initial_position:Vector2

enum entities {
	Spike,
	SchrodingerSwitch
}

var sprite:Sprite2D

@export_category("Setup")
@export var sprite_anims:Array[PackedScene]
var stored_polygons = []

func initialize():
	if entity_type == entities.Spike:
		size.y = 8
	elif entity_type == entities.SchrodingerSwitch:
		size = Vector2.ONE * 8
		var found = false
		for i in len(exists):
			if found:
				exists[i] = false
			elif exists[i]:
				found = true
		if !found:
			exists[0] = true
	add_to_group("Clip_Entity")
	initial_position = position
	position = Vector2.ZERO
	var k = CollisionPolygon2D.new()
	k.polygon = get_polygon()
	call_deferred("add_child", k)
	sprite = sprite_anims[entity_type].instantiate()
	add_child(sprite)
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.position = initial_position
	sprite.rotation_degrees = rotat
	sub_sprites.append(sprite)
	

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
	if stored_polygons == []:
		inside_window()
	else:
		uninside_window()
	
func switch_to_outline():
	get_child(0).is_alt = true
	get_child(0).is_alt = true
	show()

# Player Collision Stuff!
func player_entered(body):
	if body.get_parent() is Player:
		body.get_parent().entity_collision(self)


func inside_window():
	if entity_type == entities.SchrodingerSwitch:
		if FlagManager.set_flag(flag, true):
			for i in sub_sprites:
				i.get_child(0).play("activate")

func uninside_window():
	if entity_type == entities.SchrodingerSwitch:
		if FlagManager.set_flag(flag, false):
			for i in sub_sprites:
				i.get_child(0).play("deactivate")

# Flag Stuff!
var prev_offset
var target_offset = Vector2.ZERO
var timer:SceneTreeTimer


func activate():
	if flag > -1:
		FlagManager.on_flag(flag, flag_on, invert_flag)
		FlagManager.on_flag(flag, flag_off, !invert_flag)
		if invert_flag:
			flag_on()
			

func flag_on():
	if entity_type == entities.Spike:
		for i in sub_sprites:
			i.get_child(0).play("retract")
		monitoring = false
		monitorable = false


func flag_off():
	if entity_type == entities.Spike:
		for i in sub_sprites:
			i.get_child(0).play("extend")
		monitoring = true
		monitorable = true
