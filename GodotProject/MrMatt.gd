extends Node2D

onready var map = $TileMap
onready var tileset = map.tile_set

var dic = {
	
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_entity_name(id):
	var result = "empty"
	if id != -1:
		result = tileset.tile_get_name(id)
	return result

func compute_next_step():
	var cells = map.get_used_cells()
	cells.sort()
	var already_falling = false
	print("Start")
	for i in range(cells.size()-1, -1, -1):
		var cell = cells[i]
		var id = map.get_cellv(cell)
		var next_cell = cell + Vector2.DOWN
		var id_under = map.get_cellv(next_cell)
		var under = get_entity_name(id_under)
		var entity = tileset.tile_get_name(id)
		if entity == "boulder":
			if under == "empty" and !already_falling:
				map.set_cellv(cell, tileset.find_tile_by_name("falling_boulder"))
				already_falling = true
		elif entity == "falling_boulder":
			already_falling = true
			if under == "empty":
				map.set_cellv(cell, tileset.find_tile_by_name("empty"))
				map.set_cellv(next_cell, tileset.find_tile_by_name("falling_boulder"))
			elif under == "boulder":
				var next_cell_right = cell + Vector2.DOWN + Vector2.RIGHT
				var next_cell_left = cell + Vector2.DOWN + Vector2.LEFT
				var under_left = get_entity_name(map.get_cellv(next_cell_left))
				var under_right = get_entity_name(map.get_cellv(next_cell_right))
				if under_left == "empty":
					map.set_cellv(cell, tileset.find_tile_by_name("empty"))
					map.set_cellv(next_cell_left, tileset.find_tile_by_name("falling_boulder"))
				elif under_right == "empty":
					map.set_cellv(cell, tileset.find_tile_by_name("empty"))
					map.set_cellv(next_cell_right, tileset.find_tile_by_name("falling_boulder"))
				else:
					map.set_cellv(cell, tileset.find_tile_by_name("boulder"))
			elif under == "wall":
				map.set_cellv(cell, tileset.find_tile_by_name("boulder"))
		else:
			pass
			#print(entity)
	pass


func _on_Timer_timeout():
	compute_next_step()
