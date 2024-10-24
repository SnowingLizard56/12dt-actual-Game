# This was by far the most painful to code
@tool
class_name DimensionalWindow extends Control

const WINDOW_TILE_SIZE = Vector2i(32, 16)

@export_category("References")
@export var tilemap:TileMap
@export var outline:Line2D
@export var background_sprites:Array[Texture2D]
@export_category("Window Settings")
@export var reveals_layer:int
@export_category("Other")
@export var shadow_colour_new = Color(0.1, 0.1, 0, 0.4)
@export var shadow_colour_old = Color(0.1, 0, 0.1, 0.4)

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var offset:Vector2

var prev_tl_pos = Vector2i.ZERO
var prev_tiles = []
var layer:int

var level_obj:LevelConstructor.Level


func load_branch(pattern:TileMapPattern, level):
	if Engine.is_editor_hint(): return
	# Main Layer Tilemap
	tilemap.set_pattern(0, Vector2i(0, level.data["TileOffsets"][layer]), pattern)
	for i in level.entities:
		if !i.exists[layer] and i.entity_type == Entity.entities.Spike: continue
		if i.exists[layer] and i.entity_type == Entity.entities.SchrodingerSwitch: continue
		var k = i.sprite.duplicate(8)
		i.sub_sprites.append(k)
		k.position -= offset
		$Clip/Moving/TileMap.add_child(k)
		i.hide()
	level_obj = level
	outline.hide()
	$Area.position = get_rect().size / 2
	$Area/CollisionShape2D.shape = $Area/CollisionShape2D.shape.duplicate()
	$Area/CollisionShape2D.shape.size = get_rect().size
	# Background selection
	$Clip/Background.texture = background_sprites[layer]
	$Clip/Background.scale = Vector2.ONE * (640 / $Clip/Background.texture.get_width())
	# Add backdrop!! SHADOW
	var k = tilemap.duplicate()
	$Clip/Moving.add_child(k)
	$Clip/Moving.move_child(k, 0)
	k.position.y += 2
	if layer == 0:
		k.modulate = shadow_colour_new
	else:
		k.modulate = shadow_colour_old
	hide()


# Window Movement And Drag
func _process(delta):
	if Engine.is_editor_hint(): return
	# This ^ needs to be here bc if its not then i get an error every frame while in the editor i do NOT understand
	# Coming back to this comment like 3 months later. i think im an idiot
	# Or maybe i've just learned things 
	# I'll go with that its much more encouraging
	if dragging or hovered:
		mouse_position = get_global_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		if get_node("../../ActiveLevelFollower").moving: return
		
		# SOUND
		$PickUp.play()
		
		# Outline start
		outline.clear_points()
		for i in [Vector2.ONE, Vector2(get_rect().size.x, 1),get_rect().size, 
				Vector2(1, get_rect().size.y), Vector2(1, 0.5)]:
			outline.add_point(i)
		
		drag_offset = position - mouse_position
		dragging = true
		outline.show()
	if dragging:
		outline.global_position = mouse_position + drag_offset
		# Clamp to window extents
		outline.global_position.x = clamp(outline.global_position.x, 0 + 
				offset.x, get_viewport_rect().size.x - get_rect().size.x + offset.x)
		outline.global_position.y = clamp(outline.global_position.y, 0 + 
				offset.y, get_viewport_rect().size.y - get_rect().size.y + offset.y)
		# Lock to grid
		outline.global_position = round(outline.global_position / 8) * 8
		
		if get_node("../../ActiveLevelFollower").moving:
			dragging = false
			$MoveFail.play()
			return
		
		if Input.is_action_just_released("Click"):
			dragging = false
			# No overlap
			# Iterate over windows
			var intersects = false
			var rect = get_rect()
			rect.position += outline.position
			for window in level_obj.windows:
				if window == self: continue
				# Check intersect
				if rect.intersects(window.get_rect()):
					intersects = true
					break
			# Clip
			if intersects:
				$MoveFail.play()
			else:
				$Move.play()
				position += outline.position
				call_clip()
			outline.hide()
			outline.position = Vector2.ZERO


# Go over every window instead of just doing it alone. allows for multiple windows of the same layer.
func call_clip():
	# This is a fun function because its kinda palindromic :p
	var running_polygons
	# Reset polygons for sb and entities
	for body in level_obj.statics:
		if body.get_meta("layer") == layer: continue
		running_polygons = body.get_meta('stored_polygons')
	# Iterate over windows and clip
	for dw in level_obj.windows:
		if dw.layer == layer:
			running_polygons = dw.clip(running_polygons)
	# Apply polygons for sb and entities
	for body in level_obj.statics:
		if body.get_meta("layer") == layer: continue
		StaticbodyController.add_polygons_as_children(running_polygons, body)
	# Do entity polygons seperately
	for e in level_obj.entities:
		e.reset_polygon()
	for dw in level_obj.windows:
		dw.entity_clip()
	for e in level_obj.entities:
		e.apply_polygons()
	

func clip(polygons):
	# Get rect and adjust for errors
	$Clip/Moving.global_position = offset
	$Clip/Background.global_position = offset
	var rect = get_rect()
	rect.size.y += 0.0001
	var new_polygons
	# Iterate over terrain and entities
	for body in level_obj.statics:
		if layer != body.get_meta("layer"):
			new_polygons = StaticbodyController.clip_polygons_with_rect(polygons, 
					Rect2(position - offset, rect.size))
	return new_polygons


func entity_clip():
	for entity in level_obj.entities:
		# If exists on this layer; skip
		if entity.exists[layer]: continue
		var rect = get_rect()
		rect.size.y += 0.0001
		entity.clip_polygon(rect)


func _on_mouse_entered():
	if Engine.is_editor_hint(): return
	hovered = true


func _on_mouse_exited():
	if Engine.is_editor_hint(): return
	hovered = false


func update_editor_qualities():
	if !Engine.is_editor_hint(): return
	if fmod(size.x, 8) != 0:
		size.x = round(size.x / 8) * 8
	if fmod(size.y, 8) != 0:
		size.y = round(size.y / 8) * 8
	if fmod(position.x, 8) != 0:
		position.x = round(position.x / 8) * 8
	if fmod(position.y, 8) != 0:
		position.y = round(position.y / 8) * 8
