# oohhhhh no.
class_name DimensionalWindow extends Control

const WINDOW_TILE_SIZE = Vector2i(32, 16)

@export var tilemap:TileMap
@export var outline:Line2D

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var offset:Vector2

var prev_tl_pos = Vector2i.ZERO
var prev_tiles = []
var layer:int

var level_obj:LevelConstructor.Level
	

func load_branch(pattern:TileMapPattern, level:):
	# Main Layer Tilemap
	tilemap.clear()
	tilemap.set_pattern(0, Vector2i(level.offset/8), pattern)
	for i in level.entities:
		if !i.exists[layer]:
			continue
		tilemap.add_child(i.sprite.duplicate(8))
		i.hide()
	level_obj = level
	# outline start
	outline.clear_points()
	for i in [Vector2.ONE, Vector2(WINDOW_TILE_SIZE.x*8, 1),WINDOW_TILE_SIZE*8, Vector2(1, WINDOW_TILE_SIZE.y*8), Vector2(1, 0.5)]:
		outline.add_point(i)
	outline.hide()


# Window Movement And Drag
func _process(delta):
	# this needs to be here bc if its not then i get an error every frame while in the editor i do NOT understand
	if Engine.is_editor_hint():
		return
	if dragging or hovered:
		mouse_position = get_global_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		drag_offset = position - mouse_position
		dragging = true
		outline.show()
	if dragging:
		outline.global_position = mouse_position + drag_offset
		# Clamp to window extents
		outline.global_position.x = clamp(outline.global_position.x, 0 + offset.x, get_viewport_rect().size.x - WINDOW_TILE_SIZE.x * 8 + offset.x)
		outline.global_position.y = clamp(outline.global_position.y, 0 + offset.y, get_viewport_rect().size.y - WINDOW_TILE_SIZE.y * 8 + offset.y)
		# Lock to grid
		outline.global_position = round(outline.global_position / 8) * 8
			
		if Input.is_action_just_released("Click"):
			dragging = false
			# no overlap
			var intersects = true
			for dir in [Vector2.ZERO, 
			Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
			Vector2(0, -2), Vector2(0, 2), Vector2(-2, 0), Vector2(2, 0)]:
				# construct rect
				var rect = get_rect()
				rect.position += outline.position
				rect.position += dir*8
				# over windows
				for window in level_obj.windows:
					if window == self: continue
					#check intersect
					if !rect.intersects(window.get_rect()):
						intersects = false
						break
				#if clear, exit
				if !intersects:
					outline.position += dir*8
					break
			if !intersects:
				position += outline.position
				$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
				clip()
			outline.hide()
			outline.position = Vector2.ZERO



func clip():
	# get rect and adjust for errors
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	var rect = get_rect()
	rect.size.y += 0.0001
	# iterate over terrain and entities
	for body in level_obj.statics:
		if layer != body.get_meta("layer"):
			StaticbodyController.clip_polygons_with_rect(body.get_meta('stored_polygons'), 
				Rect2(position - offset, rect.size), body.get_meta('displayed_polygons', []), body)
	for entity in level_obj.entities:
		#if exists on this layer; skip
		if entity.exists[layer]:
			continue
		entity.clip_polygon(rect)


func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

