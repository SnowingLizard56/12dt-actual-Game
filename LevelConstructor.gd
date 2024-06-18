@tool
extends Node2D

@export_category("Relevant Scenes & Nodes")
@export var dimensional_window_scene:PackedScene
@export var player:Player

@export_category("Parent Nodes")
@export var statics_holder:Node2D
@export var window_holder:Control
@export var tilemap:TileMap

@export_category("Save to file")
@export var save = false
@export var level_name = "default"

func _ready():
	build_level("testing_levels_dir", Vector2.ZERO)
	pass

func _process(delta):
	if Engine.is_editor_hint():
		if save:
			save_level()
			save = false
		

func build_level(level:String, offset:Vector2):
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/testing_levels_dir/")
	for i in len(dir.get_files()):
		# make dw and load pattern
		var dw = dimensional_window_scene.instantiate()
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		
		# apply pattern to dw
		dw.load_branch(pattern)
		
		window_holder.add_child(dw)
		# make static bodies
		var sb = StaticBody2D.new()
		statics_holder.add_child(sb)
		var polygons = pattern.get_meta("stored_polygons", [])
		for poly in polygons:
			# generate collision polys
			var poly_node = CollisionPolygon2D.new()
			poly_node.polygon = poly
			sb.add_child(poly_node)
		# set up stuff for future & speed
		sb.set_meta("stored_polygons", polygons)
		sb.collision_mask = 0
		# Name major components
		sb.name = str(i)
		dw.name = str(i)


func save_level():
	# create level directory
	DirAccess.open("res://Levels/").make_dir(level_name)
	for i in tilemap.get_layers_count():
		# get layer tiles and polygons
		var pattern = tilemap.get_pattern(i, tilemap.get_used_cells(i))
		var polygons = StaticbodyController.generate_static_body_polygons(tilemap, i)
		# store data to file
		pattern.set_meta("stored_polygons", polygons)
		ResourceSaver.save(pattern, "res://Levels/" + level_name + "/" + str(i) + ".tres", 0)
