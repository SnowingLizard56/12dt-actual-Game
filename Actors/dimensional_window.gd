# oohhhhh no.
extends Control

const WINDOW_TILE_SIZE = Vector2i(32, 16)

@export var tilemap:TileMap
@export var player_box_scene:PackedScene

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var prev_position
var player_box
var tilemap_collision_layer

@export var internal_border_tilemap:TileMap
var prev_tl_pos = Vector2i.ZERO
var prev_tiles = []

@onready var global:globalScript = get_node("/root/Global")

# Loading
func _ready():
	global.windows.append(self)
	prev_position = position
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	tilemap_collision_layer = tilemap.tile_set.get_physics_layer_collision_layer(0)
	load_branch(tilemap)

func load_branch(parent:Node2D):
	# Main Layer Tilemap
	var k = parent.duplicate(8)
	$WindowFrame/Viewport.add_child(k)
	parent.hide()
	k.show()
	# Internal Player
	player_box = player_box_scene.instantiate()
	$WindowFrame/Viewport.add_child(player_box)
	global.playerboxes.append(player_box)
	

# Window Movement And Drag
func _process(delta):
	# Maybe make this lock to grid?
	if dragging or hovered:
		mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		drag_offset = position - mouse_position
		dragging = true
	if dragging:
		prev_position = position
		position = round((mouse_position + drag_offset) / 8) * 8
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	if Input.is_action_just_released("Click"):
		dragging = false
	
func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

# Window Borders
func apply_window_borders():
	# Apply all existing tiles on outside of window
	var tl_tile:Vector2i = internal_border_tilemap.local_to_map(position+Vector2(4, 4))
	
	# ensure no unnecessary repeats
	if tl_tile == prev_tl_pos:
		return
	prev_tl_pos = tl_tile
	
	# Remove all previous tiles
	for pos in prev_tiles:
		internal_border_tilemap.set_cell(0, pos)
	
	#Tiles top, bottom, left, right.
	var coordinates = []
	
	# Top & Bottom
	for i in range(WINDOW_TILE_SIZE.x):
		coordinates.append(tl_tile + Vector2i(i, -1))
		coordinates.append(tl_tile + Vector2i(i, WINDOW_TILE_SIZE.y))
	
	# Left & Right
	for i in range(WINDOW_TILE_SIZE.y):
		coordinates.append(tl_tile + Vector2i(-1, i))
		coordinates.append(tl_tile + Vector2i(WINDOW_TILE_SIZE.x, i))
	
	# go wild
	place_cells(coordinates)

func place_cells(coordinates):
	# apply all changes calculated above
	prev_tiles = []
	for tile_pos in coordinates:
		if check_tile_at_coordinates(tile_pos):
			prev_tiles.append(tile_pos)
			internal_border_tilemap.set_cell(0, tile_pos, 2, Vector2i.ZERO)

func check_tile_at_coordinates(coord):
	for window in global.windows:
		if window.tilemap.get_cell_tile_data(0, coord):
			return true
	return false


# Inner & Outer Hitbox Detection
func outer_border_body_enters(body):
	if body.has_method("on_window_entered"):
		body.on_window_entered(self)


func outer_border_body_exits(body):
	if body.has_method("on_window_exited"):
		body.on_window_exited(self)


func body_enters_inner_border(body):
	if body == global.player:
		body.overlapping_inner = true

func body_exits_inner_border(body):
	if body == global.player:
		body.overlapping_inner = false
