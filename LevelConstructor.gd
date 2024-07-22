@tool
extends Node2D

const VIEWPORT_SIZE = Vector2(640, 360)

var building_thread: Thread

var built_levels = []

@export_category("Relevant Scenes")
@export var dimensional_window_scene:PackedScene
@export var entity_scene:PackedScene

@export_category("Relevant Nodes")
@export var player:Player
@export var tilemap:TileMap

@export_category("Holders")
@export var statics_holder:Node2D
@export var window_holder:Control
@export var entity_holder:Node2D

@export_category("Save to file")
enum save_states {Unsaved, Save}
@export var save:save_states
@export var level_name = "default"

@export_category("Save Options")
@export var window_sizes_override:Array[Vector2] = []
@export var level_above = ""
@export var level_below = ""
@export var level_left = ""
@export var level_right = ""

func _ready():
	if Engine.is_editor_hint():
		tilemap.show()
	else:
		for i in [statics_holder, window_holder, entity_holder]:
			for c in i.get_children():
				c.queue_free()
		build_level("testing_levels_dir", Vector2.ZERO, true, true)
		tilemap.hide()

func _process(_delta):
	if Engine.is_editor_hint():
		if save == save_states.Save:
			save_level()
			save = save_states.Unsaved
		

func build_level(level:String, offset:Vector2, active:bool, load_surroundings=false):
	# Prepare level class
	var level_obj = Level.new()
	level_obj.level_name = level
	
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/"+level+"/")
	
	# extract data dict
	var data = ResourceLoader.load(dir.get_current_dir() + "/_.tres") as Resource
	data = data.get_meta("_")
	level_obj.data = data
	
	# load entities
	for e in data['Entities']:
		var k:Entity = entity_scene.instantiate()
		k.size = e[0]
		k.exists = e[1]
		k.entity_type = e[2]
		k.position = e[3] + offset
		entity_holder.add_child(k)
		k.initialize()
		level_obj.entities.append(k)
	
	for i in len(dir.get_files()):
		if dir.get_files()[i] == "_.tres":
			continue
		# make dw and load pattern
		var dw = dimensional_window_scene.instantiate()
		window_holder.add_child(dw)
		dw.layer = i
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		
		# apply pattern to dw
		dw.load_branch(pattern, level_obj)
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
		
		# add dw and sb to level obj
		level_obj.windows.append(dw)
		level_obj.statics.append(sb)
		
		# apply offset
		dw.position = offset
		sb.position = offset
	# load surroundings
	if load_surroundings:
		for i in 4:
			if data["Connections"][i] != "":
				# U D L R
				build_level(data["Connections"][i], 
				[Vector2(0, -VIEWPORT_SIZE.y), 
				Vector2(0, VIEWPORT_SIZE.y),
				Vector2(-VIEWPORT_SIZE.x, 0), 
				Vector2(VIEWPORT_SIZE.x, 0)
				][i] + offset, 
				false, false)
	# activate/deactivate
	if active:
		level_obj.activate()
		player.position = data['PlayerSpawn']
	else:
		level_obj.deactivate()
	print("level built")
	built_levels.append(level_obj)
	return level_obj


func save_level():
	# construct data dict
	var data = Resource.new()
	var entities = []
	
	for i in entity_holder.get_children():
		entities.append([i.size, i.exists, i.entity_type, i.position])
	
	data.set_meta("_", {
		"PlayerSpawn": player.position,
		"Entities": entities,
		"Connections": [level_above, level_below, level_left, level_right]
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
	print("level saved")


func player_exit_left(body):
	pass # Replace with function body.


func player_exit_up(body):
	pass # Replace with function body.


func player_exit_right(body):
	pass # Replace with function body.


func player_exit_down(body):
	pass # Replace with function body.


class Level:
	var level_name:String
	var entities = []
	var statics = []
	var windows = []
	var data
	
	func deactivate():
		for i in entities:
			i.collision_layer = 0
			i.collision_mask = 0
		for i in statics:
			i.collision_layer = 0
		for i in windows:
			i.hide()
		
	func activate():
		for i in entities:
			i.collision_layer = 4
			i.collision_mask = 6
		for i in statics:
			i.collision_layer = 1
			i.collision_mask = 0
		for i in windows:
			i.show()
			
		
	func unload():
		pass
	
	func load_surroundings():
		pass
	
