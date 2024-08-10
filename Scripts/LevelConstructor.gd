@tool
class_name LevelConstructor extends Node2D

const VIEWPORT_SIZE = Vector2(640, 360)
const OFFSETS = [Vector2(0, -VIEWPORT_SIZE.y), 
				Vector2(0, VIEWPORT_SIZE.y),
				Vector2(-VIEWPORT_SIZE.x, 0), 
				Vector2(VIEWPORT_SIZE.x, 0)]

var build_queue:Array[Callable] = []
var born_to_die: Array[Node] = []
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
enum save_states {File, Save, Load, Clear}
@export var save:save_states
@export var level_name = "default"

@export_category("Save Options")
@export var window_sizes_override:Array[Vector2] = []
@export var level_above = ""
@export var level_below = ""
@export var level_left = ""
@export var level_right = ""

@export_category("Runtime Options")
@export var start_game_level_name = ""

func _ready():
	if Engine.is_editor_hint():
		tilemap.show()
		limbo_tmap.hide()
	else:
		for i in [statics_holder, window_holder, entity_holder]:
			for c in i.get_children():
				c.queue_free()
		
		limbo_tmap.clear()
		build_level(start_game_level_name, Vector2.ZERO, true)
		tilemap.hide()
		limbo_tmap.show()


func _process(_delta):
	if Engine.is_editor_hint():
		if save == save_states.Save:
			save_level()
			save = save_states.File
		if save == save_states.Load:
			clear_editor()
			load_level_to_editor()
			save = save_states.File
		if save == save_states.Clear:
			clear_editor()
			save = save_states.File
	elif build_queue != []:
		build_queue[0].call()
		build_queue.remove_at(0)


func clear_editor():
	if !Engine.is_editor_hint(): return
	# Kill entities, clear tilemap
	tilemap.clear()
	for i in entity_holder.get_children():
		i.queue_free()
	for i in window_holder.get_children():
		i.queue_free()
	level_above = ""
	level_below = ""
	level_left = ""
	level_right = ""
	print("Editor Cleared")
	

func load_level_to_editor():
	if !Engine.is_editor_hint(): return
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
		k.rotat = e[4]
		k.flag = e[5]
		k.invert_flag = e[6]
		entity_holder.add_child(k)
		k.owner = owner
		k.name = "Entity_" + str(i) + " - " + str(k.entity_type)
	# load windows
	for i in len(data["Windows"]):
		var w = data["Windows"][i]
		var k = dimensional_window_scene.instantiate()
		k.size = w[0].size
		k.position = w[0].position
		k.reveals_layer = w[1]
		window_holder.add_child(k)
		k.owner = owner
		k.name = "window - layer " + str(w[1])
	# tilemaps
	for i in len(dir.get_files()):
		if dir.get_files()[i] == "_.tres": continue
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		tilemap.set_pattern(i, Vector2i(0, data["TileOffsets"][i]), pattern)
	
	# data
	level_above = data["Connections"][0]
	level_below = data["Connections"][1]
	level_left = data["Connections"][2]
	level_right = data["Connections"][3]
	
	player.position = data["PlayerSpawn"]
	print("Loaded level '", level_name, "' to editor")


func build_level(level:String, offset:Vector2, active:bool):
	# TODO - split level construction over multiple frames.
	# Prepare level class
	var level_obj = Level.new()
	level_obj.level_name = level
	level_obj.offset = offset
	level_obj.constructor = self
	var level_index = len(built_levels)
	built_levels.append(level_obj)
	
	# navigate to level directory
	var dir = DirAccess.open("res://Levels/"+level+"/")
	
	# extract data dict
	var limbo_pattern = ResourceLoader.load(dir.get_current_dir() + "/_.tres") as TileMapPattern
	var data = limbo_pattern.get_meta("_")
	level_obj.data = data
	
	if active:
		# load entities
		build_entities(data, offset, level_index)
		# dw and sb
		build_collision(dir, offset, level_index)
		build_windows(dir, data, offset, level_index)
		# load surroundings
		post_level_build(data, offset, level_index, active, limbo_pattern)
	else:
		build_queue.append(build_entities.bind(data, offset, level_index))
		build_queue.append(build_collision.bind(dir, offset, level_index))
		build_queue.append(build_windows.bind(dir, data, offset, level_index))
		build_queue.append(post_level_build.bind(data, offset, level_index, active, limbo_pattern))
	return level_index


func build_entities(data, offset:Vector2, level_index:int):
	for e in data['Entities']:
		var k:Entity = entity_scene.instantiate()
		k.size = e[0]
		k.exists = e[1]
		k.entity_type = e[2]
		k.position = e[3] + offset
		k.rotat = e[4]
		k.flag = e[5]
		k.invert_flag = e[6]
		entity_holder.add_child(k)
		k.initialize()
		built_levels[level_index].entities.append(k)
		k.name = "Entity - " + str(k.entity_type)


func build_collision(dir, offset:Vector2, level_index:int):
	for i in len(dir.get_files()):
		if dir.get_files()[i] == "_.tres": continue
		# make static bodies
		var sb = StaticBody2D.new()
		statics_holder.add_child(sb)
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ dir.get_files()[i]) as TileMapPattern
		var polygons = pattern.get_meta("stored_polygons", [])
		for poly in polygons:
			# generate collision polys
			var poly_node = CollisionPolygon2D.new()
			poly_node.polygon = poly
			sb.call_deferred("add_child", poly_node)
		# set up stuff for future & speed
		sb.set_meta("stored_polygons", polygons)
		sb.set_meta("layer", i)
		sb.collision_mask = 0
		# Name major components
		sb.name = str(i)
		
		# add sb to level obj
		built_levels[level_index].statics.append(sb)
		
		# apply offset
		sb.position = offset


func build_windows(dir, data, offset:Vector2, level_index:int):
	for i in data["Windows"]:
		#make dw + load pattern
		var dw:Control = dimensional_window_scene.instantiate()
		dw.layer = i[1]
		# move and size
		dw.offset = offset
		dw.position = offset + i[0].position
		dw.size = i[0].size
		window_holder.add_child(dw)
		
		built_levels[level_index].windows.append(dw)
		#apply pattern
		var pattern = ResourceLoader.load(dir.get_current_dir() +"/"+ str(i[1]) + ".tres") as TileMapPattern
		dw.load_branch(pattern, built_levels[level_index])


func post_level_build(data, offset:Vector2, level_index:int, active:bool, limbo_pattern):
	if active:
		for i in 4:
			if data["Connections"][i] != "":
				# U D L R
				build_level(data["Connections"][i],
				OFFSETS[i] + offset, 
				false)
	# activate/deactivate
	if active:
		built_levels[level_index].activate()
		player.position = data['PlayerSpawn']
	else:
		built_levels[level_index].deactivate()
	# build limbo area 
	limbo_tmap.set_pattern(0, Vector2i(offset/8), limbo_pattern)
	# outline entities
	for i in built_levels[level_index].entities:
		i.switch_to_outline()


func save_level():
	if !Engine.is_editor_hint(): return
	# construct data dict
	var entities = []
	
	for i in entity_holder.get_children():
		entities.append([i.size, i.exists, i.entity_type, i.position, i.rotat, i.flag, i.invert_flag])
	# create level directory
	DirAccess.open("res://Levels/").make_dir(level_name)
	var limbo_pos_set = []
	var tileoffsets = []
	for i in tilemap.get_layers_count():
		# get layer tiles and polygons
		# get non-decor tiles
		var terrain_cells = []
		tileoffsets.append(45)
		for coord in tilemap.get_used_cells(i):
			if tilemap.get_cell_tile_data(i, coord).get_custom_data("is_decor"): continue
			terrain_cells.append(coord)
			if tileoffsets[i] > coord.y:
				tileoffsets[i] = coord.y
		#move on. immediately dont use them
		var pattern:TileMapPattern = tilemap.get_pattern(i, tilemap.get_used_cells(i))
		var polygons = StaticbodyController.generate_static_body_polygons(tilemap, i)
		# store data to file
		pattern.set_meta("stored_polygons", polygons)
		ResourceSaver.save(pattern, "res://Levels/" + level_name + "/" + str(i) + ".tres")
		# update total save
		BetterTerrain.set_cells(limbo_tmap, 0, tilemap.get_used_cells(i), 0)
		BetterTerrain.update_terrain_cells(limbo_tmap, 0, terrain_cells)
		limbo_pos_set += terrain_cells
	
	# limbo tmap
	var data = limbo_tmap.get_pattern(0, limbo_pos_set)
	for i in limbo_pos_set:
		limbo_tmap.erase_cell(0, i)
	
	# Windows
	var windows = []
	for i in window_holder.get_children():
		windows.append([Rect2(i.position, i.size), i.reveals_layer])
	# give data to meta
	data.set_meta("_", {
		"PlayerSpawn": player.position,
		"Entities": entities,
		"Connections": [level_above, level_below, level_left, level_right],
		"Windows": windows,
		"TileOffsets": tileoffsets
	})
	
	# save data dict
	ResourceSaver.save(data, "res://Levels/" + level_name + "/_.tres")
	print("Level saved to '" + "res://Levels/" + level_name + "'")


func enter_new_screen():
	var index
	# figure out direction
	if player.position.x > current_level.offset.x + VIEWPORT_SIZE.x:
		index = 3
	elif player.position.x < current_level.offset.x:
		index = 2
	elif player.position.y > current_level.offset.y + VIEWPORT_SIZE.y:
		index = 1
	elif player.position.y < current_level.offset.y: 
		index = 0
	#continue
	if current_level.data["Connections"][index] == "": return
	allow_switch = false
	# Activate level
	var level_obj
	for i in built_levels:
		if i.offset == current_level.offset + OFFSETS[index]:
			i.activate()
			i.load_surroundings()
			level_obj = i
			break
	# Move camera
	get_node("../ActiveLevelFollower").target_position += OFFSETS[index]
	get_node("../ActiveLevelFollower").moving = true
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
	var counter
	
	func deactivate():
		for i in entities:
			i.collision_layer = 0
			i.collision_mask = 0
		active = false
		
	func activate():
		FlagManager.clear_flags()
		
		for i in constructor.built_levels:
			if !i.active: continue
			i.deactivate()
		constructor.current_level = self
	
		for i in entities:
			i.collision_layer = 4
			i.collision_mask = 6
			i.activate()
		for i in windows:
			i.show()
		for i in 2:
			for w in windows:
				if w.layer == i:
					w.call_deferred("call_clip")
		active = true
			
		
	func unload():
		constructor.born_to_die.append_array(entities + statics + windows)
		constructor.built_levels.erase(self)
	
	func load_surroundings():
		# Unload
		var kill_list = []
		for i in constructor.built_levels:
			if i == self: continue
			kill_list.append(i)
		for i in kill_list:
			i.unload()
			constructor.built_levels.erase(i)
		for i in 4:
			var l = data["Connections"][i]
			if !l: continue
			var build_callable = constructor.build_level.bind(l, offset + OFFSETS[i], false)
			constructor.build_queue.append(build_callable)


func _on_active_level_follower_target_met():
	for i in born_to_die:
		i.queue_free()
	born_to_die = []
	
