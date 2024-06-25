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
	if !Engine.is_editor_hint():
		build_level("testing_levels_dir", Vector2.ZERO)
	pass

func _process(_delta):
	if Engine.is_editor_hint():
		if save:
			save_level()
			save = false
		

func build_level(level:String, _offset:Vector2):
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/"+level+"/")
	# extract data dict
	var data = ResourceLoader.load(dir.get_current_dir() + "/_.tres") as Resource
	data = data.get_meta("_")
	
	for i in len(dir.get_files()):
		if dir.get_files()[i] == "_.tres":
			continue
		# make dw and load pattern
		var dw = dimensional_window_scene.instantiate()
		window_holder.add_child(dw)
		dw.layer = i
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		
		# apply pattern to dw
		dw.load_branch(pattern)
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
	# apply data
	player.position = data['PlayerSpawn']
	return data


func save_level():
	# construct data dict
	var data = Resource.new()
	data.set_meta("_", {
		"PlayerSpawn": player.position
	})
	
	# create level directory
	DirAccess.open("res://Levels/").make_dir(level_name)
	# save data dict
	ResourceSaver.save(data, "res://Levels/" + level_name + "/_.tres")
	for i in tilemap.get_layers_count():
		# get layer tiles and polygons
		var pattern:TileMapPattern = tilemap.get_pattern(i, tilemap.get_used_cells(i))
		var polygons = StaticbodyController.generate_static_body_polygons(tilemap, i)
		# store data to file
		pattern.set_meta("stored_polygons", polygons)
		ResourceSaver.save(pattern, "res://Levels/" + level_name + "/" + str(i) + ".tres")
