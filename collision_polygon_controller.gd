# https://gist.github.com/afk-mario/15b5855ccce145516d1b458acfe29a28
class_name StaticbodyController extends RefCounted

const CELL_SIZE = Vector2(8,8)

# please for the love of god rename this function later
# this is VERY O(n^2) so. figure that out future me
static func generate_static_body_polygons(tilemap:TileMap, layer:int, static_body_parent:Node = null):
	# Static body will hold all the collision polygons!
	var collision_holder
	if static_body_parent:
		collision_holder = StaticBody2D.new()
		static_body_parent.add_child(collision_holder)
		
	var polygons = []
	var used_cells = tilemap.get_used_cells(layer)
	
	# Make edges
	for cell in used_cells:
		polygons.append(get_tile_polygon(get_points(cell)))
	
	# Merge tiles by comparing each tile to each other tile 
	while true:
		var deathrow_polygons = []
		var deathrow_index = {}
		for i in polygons.size():
			# if already on deathrow, skip it
			if deathrow_index.get(i, false):
				continue
			
			var polygon_1 = polygons[i]
			
			# here comes the squared.
			# nested loops make me feel sick. this is 3 deep now!! ew!!!!!
			for j in i:
				# if on deathrow!
				if deathrow_index.get(i, false):
					continue
				
				var polygon_2 = polygons[j]
				# this gives a list for whatever reason
				var new_polygon = Geometry2D.merge_polygons(polygon_1, polygon_2)
				
				if len(new_polygon) != 1:
					continue
					
				# Replace Polygon Hooray
				polygons[j] = new_polygon[0]
				
				# CRIMINAL POLYGON!!! DEATH SENTENCE!!
				deathrow_polygons.append(polygon_1)
				deathrow_index[i] = true
				break
		# Outside of the squared!d
		# thank goodness i was getting worried
		
		if len(deathrow_polygons) == 0:
			# the world is free of criminals!
			# you could also frame it as though 
			# they have all undergone cognitive behavioural therapy
			# but the way i have named my variables may make that difficult
			break
		
		# MURDERRRR
		for poly in deathrow_polygons:
			polygons.erase(poly)
	# outside of ALL the loops thank god
	if static_body_parent:
		for poly in polygons:
			var poly_node = CollisionPolygon2D.new()
			poly_node.polygon = poly
			collision_holder.add_child(poly_node)
		collision_holder.set_meta("stored_polygons", polygons)
		collision_holder.collision_mask = 0
	return polygons


# i makea all da points on da tile from da one point on da tile
static func get_points(pos):
	#01
	#23
	return [
		Vector2(pos.x * CELL_SIZE.x, (pos.y + 1) * CELL_SIZE.y), #2
		Vector2(pos.x * CELL_SIZE.x, pos.y * CELL_SIZE.y), #0
		Vector2((pos.x + 1) * CELL_SIZE.x, pos.y * CELL_SIZE.y), #1
		Vector2((pos.x + 1) * CELL_SIZE.x, (pos.y + 1) * CELL_SIZE.y) #3
	]

# i makea da polygon from the places on da tile 
# (directly following from prev function)
static func get_tile_polygon(points):
	return [points[0], points[1], points[1], points[2], points[2], points[3], points[3], points[0]]


static func clip_polygons_with_rect(polygons:Array, rect:Rect2, output_parent:Node=null):
	#01
	#32
	var rect_polygon = [
		rect.position, #0
		rect.position + Vector2(rect.size.x, 0), #1
		rect.position + rect.size, #2
		rect.position + Vector2(0, rect.size.y) #3
		]

	# split and free the old ones
	var new_polygons = []
	for i in polygons:
		new_polygons.append_array(Geometry2D.clip_polygons(i, rect_polygon))
	# poof
	if output_parent:
		for i in output_parent.get_children():
			if i is CollisionPolygon2D:
				i.queue_free()
			
		# make and apply the new ones
		for i in new_polygons:
			if Geometry2D.is_polygon_clockwise(i):
				push_warning("Polygon Split Error")
			var k = CollisionPolygon2D.new()
			output_parent.add_child(k)
			k.set_deferred('polygon', i)
	return new_polygons


static func rotate_polygon(polygon:PackedVector2Array, pivot:Vector2, rotation_degrees:int):
	var out = []
	for i in polygon:
		out.append((i - pivot).rotated(deg_to_rad(rotation_degrees)) + pivot)
	return out
	
