# Inspiration taken from https://gist.github.com/afk-mario/15b5855ccce145516d1b458acfe29a28
class_name StaticbodyController extends RefCounted

const CELL_SIZE = Vector2(8,8)
const DELTA = 0.001


# Please for the love of god rename this function later
# This is VERY O(n^2) so. figure that out future me
# Future me talking: I Did Not
static func generate_static_body_polygons(tilemap:TileMap,layer:int,static_body_parent:Node=null):
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
			# If already on deathrow, skip it
			if deathrow_index.get(i, false):
				continue
			
			var polygon_1 = polygons[i]
			
			# Here comes the squared.
			# Nested loops make me feel sick. this is 3 deep now!! ew!!!!!
			for j in i:
				# If on deathrow!
				if deathrow_index.get(i, false):
					continue
				
				var polygon_2 = polygons[j]
				# This gives a list for whatever reason
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
		# Thank goodness i was getting worried
		
		if len(deathrow_polygons) == 0:
			# The world is free of criminals!
			# You could also frame it as though 
			# They have all undergone cognitive behavioural therapy
			# But the way i have named my variables may make that difficult
			break
		
		# MURDERRRR
		for poly in deathrow_polygons:
			polygons.erase(poly)
	# Outside of ALL the loops thank god
	if static_body_parent:
		for poly in polygons:
			var poly_node = CollisionPolygon2D.new()
			poly_node.polygon = poly
			collision_holder.add_child(poly_node)
		collision_holder.set_meta("stored_polygons", polygons)
		collision_holder.collision_mask = 0
	return polygons


# I makea all da points on da tile from da one point on da tile
# Future me talking again: what
static func get_points(pos):
	# 01
	# 23
	return [
		Vector2(pos.x * CELL_SIZE.x, (pos.y + 1) * CELL_SIZE.y), #2
		Vector2(pos.x * CELL_SIZE.x, pos.y * CELL_SIZE.y), #0
		Vector2((pos.x + 1) * CELL_SIZE.x, pos.y * CELL_SIZE.y), #1
		Vector2((pos.x + 1) * CELL_SIZE.x, (pos.y + 1) * CELL_SIZE.y) #3
	]


# I makea da polygon from the places on da tile 
# (directly following from prev function)
static func get_tile_polygon(points):
	return [points[0], points[1], points[1], points[2], points[2], points[3], points[3], points[0]]


static func clip_polygons_with_rect(polygons:Array, rect:Rect2, output_parent:Node=null):
	# 01
	# 32
	var rect_polygon = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
		]
	
	# Check for what type of clip to run
	var contained
	for i in len(polygons):
		var p = polygons[i]
		if len(Geometry2D.intersect_polyline_with_polygon(p, rect_polygon)) != 0: continue
		if Geometry2D.is_point_in_polygon(rect_polygon[0], p):
			contained = i
			break
	var clip_polygons = []
	clip_polygons.append_array(polygons)
	if contained is int:
		# Cut along a line so that two polygons can be created
		var polyline = [
			Vector2(rect.position.x, 0),
			Vector2(rect.position.x, 360)
		]
		# Delete the inside of the rect
		clip_polygons.remove_at(contained)
		polyline = Geometry2D.offset_polyline(polyline, DELTA)[0]
		clip_polygons.append_array(Geometry2D.clip_polygons(polygons[contained], polyline))
	
	var new_polygons = []
	for i in clip_polygons:
		new_polygons.append_array(Geometry2D.clip_polygons(i, rect_polygon))
	# If given a parent, add the polygons to that parent
	if output_parent:
		add_polygons_as_children(polygons, output_parent)
	return new_polygons


# Rotates a given polygon about a point
static func rotate_polygon(polygon:PackedVector2Array, pivot:Vector2, rotation_degrees:int):
	var out = []
	for i in polygon:
		out.append((i - pivot).rotated(deg_to_rad(rotation_degrees)) + pivot)
	return out
	
	
static func add_polygons_as_children(polygons:Array, output_parent:Node):
	# Out with the old
	for i in output_parent.get_children():
		if i is CollisionPolygon2D:
			i.queue_free()
		
	# In with the new
	for i in polygons:
		var k = CollisionPolygon2D.new()
		output_parent.add_child(k)
		k.set_deferred('polygon', i)
