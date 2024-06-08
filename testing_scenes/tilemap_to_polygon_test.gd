extends Area2D

const CELL_SIZE = Vector2(8,8)

func _ready():
	for i in 6:
		print(i)

# please for the love of god rename this function later
func do_the_thing(tilemap:TileMap):
	# Static body will hold all the collision polygons!
	var collision_holder = StaticBody2D.new()
	add_child(collision_holder)
	
	var polygons = []
	var used_cells = tilemap.get_used_cells(0)
	
	# Make edges
	for cell in used_cells:
		polygons.append(get_tile_polygon(get_points(cell)))
	
	while true:
		var deathrow_polygons = []
		var deathrow_index = {}
		for i in polygons.size():
			pass

# i makea all da points on da tile from da one point on da tile
func get_points(pos):
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
func get_tile_polygon(points):
	return [points[0], points[1], points[1], points[2], points[2], points[3], points[3], points[0]]
