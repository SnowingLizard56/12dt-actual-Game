# oohhhhh no.
class_name DimensionalWindow extends Control

const WINDOW_TILE_SIZE = Vector2i(32, 16)

@export var tilemap:TileMap

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var prev_position:Vector2
var offset:Vector2

var prev_tl_pos = Vector2i.ZERO
var prev_tiles = []
var layer:int

var level_obj:LevelConstructor.Level

# Loading
func _ready():
	prev_position = position
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	clip()
	

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
	if dragging:
		# Save prev
		prev_position = position
		# Move
		position = mouse_position + drag_offset
		# Prevent overlap with other windows
		for child in len(get_parent().get_children()):
			var w:DimensionalWindow = get_parent().get_children()[child]
			if w != self:
				if w.get_rect().intersects(get_rect()):
					prevent_overlap(delta)
		# Clamp to window extents
		position.x = clamp(position.x, 0 + offset.x, get_viewport_rect().size.x - WINDOW_TILE_SIZE.x * 8 + offset.x)
		position.y = clamp(position.y, 0 + offset.y, get_viewport_rect().size.y - WINDOW_TILE_SIZE.y * 8 + offset.y)
		# Lock to grid
		position = round(position / 8) * 8
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
		clip()
			
	if Input.is_action_just_released("Click"):
		dragging = false


func clip():
	# get rect and adjust for errors
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

# WIP
func prevent_overlap(_delta:float):
	var velocity = position - prev_position
	#reset charbody position
	$PreventOverlap.position = Vector2.ZERO
	#reset self position
	position = prev_position
	var collision:KinematicCollision2D = $PreventOverlap.move_and_collide(velocity)
	position += $PreventOverlap.position
	if collision:
		var normal:Vector2 = collision.get_normal()
		if normal.y:
			position.x = mouse_position.x + drag_offset.x
		elif normal.x:
			position.y = mouse_position.y + drag_offset.y
	$PreventOverlap.position = Vector2.ZERO

func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false
