@tool
class_name LevelConstructor extends Node2D

const VIEWPORT_SIZE = Vector2(640, 360)
const OFFSETS = [Vector2(0, -VIEWPORT_SIZE.y), 
				Vector2(0, VIEWPORT_SIZE.y),
				Vector2(-VIEWPORT_SIZE.x, 0), 
				Vector2(VIEWPORT_SIZE.x, 0)]
var building_thread: Thread

var built_levels = []
var current_level:Level

var allow_switch = false

@export_category("Relevant Scenes")
@export var dimensional_window_scene:PackedScene
@export var entity_scene:PackedScene

@export_category("Relevant Nodes")
@export var player:Player
@export var tilemap:TileMap
@export var limbo_tmap:TileMap

@export_category("Holders")
@export var statics_holder:Node2D
@export var window_holder:Control
@export var entity_holder:Node2D

@export_category("Save to file")
enum save_states {Unsaved, Save, Load_Doesnt_Work}
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
		if save == save_states.Load_Doesnt_Work:
			load_level_to_editor()
			save = save_states.Unsaved


func load_level_to_editor():
	if !Engine.is_editor_hint(): return
	
	# Kill entities, clear tilemap
	tilemap.clear()
	for i in entity_holder.get_children():
		i.queue_free()
	
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/"+level_name+"/")
	# extract data dict
	var limbo_pattern = ResourceLoader.load(dir.get_current_dir() + "/_.tres") as TileMapPattern
	var data = limbo_pattern.get_meta("_")
	# load entities
	for i in len(data['Entities']):
		var e = data['Entities'][i]
		var k:Entity = entity_scene.instantiate()
		k.size = e[0]
		k.exists = e[1]
		k.entity_type = e[2]
		k.position = e[3]
		entity_holder.add_child(k)
		k.owner = owner
		k.name = "Entity_" + str(i) + " - " + str(k.entity_type)
	
	# tilemaps
	for i in len(dir.get_files()):
		if dir.get_files()[i] == "_.tres": continue
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		tilemap.set_pattern(i, Vector2i.ZERO, pattern)
	
	# data
	level_above = data["Connections"][0]
	level_below = data["Connections"][1]
	level_left = data["Connections"][2]
	level_right = data["Connections"][3]
	
	player.position = data["PlayerSpawn"]
	print("Loaded level '", level_name, "' to editor")

func build_level(level:String, offset:Vector2, active:bool, load_surroundings=false):
	# Prepare level class
	var level_obj = Level.new()
	level_obj.level_name = level
	level_obj.offset = offset
	level_obj.constructor = self
	
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/"+level+"/")
	
	# extract data dict
	var limbo_pattern = ResourceLoader.load(dir.get_current_dir() + "/_.tres") as TileMapPattern
	var data = limbo_pattern.get_meta("_")
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
		if dir.get_files()[i] == "_.tres": continue
		# make dw and load pattern
		var dw = dimensional_window_scene.instantiate()
		window_holder.add_child(dw)
		dw.layer = i
		dw.offset = offset
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
		sb.set_meta("layer", i)
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
				OFFSETS[i] + offset, 
				false, false)
	# activate/deactivate
	if active:
		level_obj.activate()
		player.position = data['PlayerSpawn']
	else:
		level_obj.deactivate()
	print(level, " built at ", offset)
	built_levels.append(level_obj)
	# build limbo area
	BetterTerrain.set_cells(limbo_tmap, 0, limbo_pattern.get_used_cells(), 0, Vector2i(offset/8))
	BetterTerrain.update_terrain_cells(limbo_tmap, 0, limbo_pattern.get_used_cells(), true, Vector2i(offset/8))
	return level_obj


func save_level():
	if !Engine.is_editor_hint(): return
	# construct data dict
	var data = TileMapPattern.new()
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
	for i in tilemap.get_layers_count():
		# get layer tiles and polygons
		var pattern:TileMapPattern = tilemap.get_pattern(i, tilemap.get_used_cells(i))
		var polygons = StaticbodyController.generate_static_body_polygons(tilemap, i)
		# store data to file
		pattern.set_meta("stored_polygons", polygons)
		ResourceSaver.save(pattern, "res://Levels/" + level_name + "/" + str(i) + ".tres")
		# update total save
		for coord in tilemap.get_used_cells(i):
			data.set_cell(coord)
	# save data dict
	ResourceSaver.save(data, "res://Levels/" + level_name + "/_.tres")
	print("Level saved to '" + "res://Levels/" + level_name + "'")


func player_exit_left(body):
	if !body is Player: return
	enter_new_screen(2)


func player_exit_up(body):
	if !body is Player: return
	enter_new_screen(0)


func player_exit_right(body):
	if !body is Player: return
	enter_new_screen(3)


func player_exit_down(body):
	if !body is Player: return
	enter_new_screen(1)
	

func enter_new_screen(index:int):
	if current_level.data["Connections"][index] == "": return
	print("Player exited " + str(index))
	allow_switch = false
	# Activate level
	var level_obj
	for i in built_levels:
		if i.offset == current_level.offset + OFFSETS[index]:
			print(i.level_name, " activated at ", i.offset)
			i.activate()
			i.load_surroundings()
			level_obj = i
			break
	# Move camera
	get_node("../Camera2D").target_position += OFFSETS[index]
	get_node("../Camera2D").moving = true
	# Reset player spawn
	get_node("../Player").spawn_position = level_obj.data["PlayerSpawn"] + level_obj.offset
	

class Level:
	var level_name:String
	var entities = []
	var statics = []
	var windows = []
	var data
	var active = false
	var offset:Vector2
	var constructor:LevelConstructor
	
	func deactivate():
		for i in entities:
			i.collision_layer = 0
			i.collision_mask = 0
		for i in windows:
			i.hide()
		active = false
		
	func activate():
		for i in constructor.built_levels:
			if !i.active: continue
			i.deactivate()
		constructor.current_level = self
	
		for i in entities:
			i.collision_layer = 4
			i.collision_mask = 6
		for i in windows:
			i.show()
		active = true
			
		
	func unload():
		for i in entities + statics + windows:
			i.queue_free()
		constructor.built_levels.erase(self)
	
	func load_surroundings():
		# Unload
		var kill_list = []
		var skip_list = []
		for i in constructor.built_levels:
			if i == self: continue
			# is a correct neighbour (U D L R)
			var cont = false
			for dir in 4:
				if i.offset == OFFSETS[dir] + offset and i.level_name == data["Connections"][dir]:
					cont = true
					skip_list.append(i)
					continue
			if cont: continue
			kill_list.append(i)
		for i in kill_list:
			i.unload()
			constructor.built_levels.erase(i)
