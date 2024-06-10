# oohhhhh no.
@tool
extends Control

const WINDOW_TILE_SIZE = Vector2i(32, 16)

@export var tilemap:TileMap

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var prev_position

var prev_tl_pos = Vector2i.ZERO
var prev_tiles = []

@export var statics_holder:Node

var global:globalScript

@export var collision_polygons_generated:bool = false
# Loading
func _ready():
	if Engine.is_editor_hint():
		return
	global = get_node("/root/Global")
	global.windows.append(self)
	prev_position = position
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	load_branch(tilemap)

func load_branch(parent:Node2D):
	# Main Layer Tilemap
	var k = parent.duplicate(8)
	$WindowFrame/Viewport.add_child(k)
	parent.hide()
	k.show()
	

# Window Movement And Drag
func _process(_delta):
	if Engine.is_editor_hint():
		if !collision_polygons_generated and tilemap and statics_holder:
			collision_polygons_generated = true
			# Remove old
			for i in statics_holder.get_children():
				if i.name == name:
					i.free()
					break
			# make new
			var k = StaticbodyController.generate_static_body_polygons(tilemap, statics_holder)
			k.owner = owner
			k.name = name
			for i in k.get_children():
				i.owner = owner
		return
	
	if dragging or hovered:
		mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		drag_offset = position - mouse_position
		dragging = true
	if dragging:
		prev_position = position
		position = round((mouse_position + drag_offset) / 8) * 8
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
		for body in statics_holder.get_children():
			if body.name != name:
				var rect = get_rect()
				rect.size.y += 0.0001
				StaticbodyController.circumcise_the_static_body(body, rect)
	if Input.is_action_just_released("Click"):
		dragging = false
	
func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false
