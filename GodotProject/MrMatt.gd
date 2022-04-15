extends Node2D

onready var map = $TileMap
onready var tileset = map.tile_set
onready var timer = $Timer

var can_move = true
var desired_input = Vector2.ZERO

var X_MIN = 0
var X_MAX = 23
var Y_MIN = 0
var Y_MAX = 23

var character_position = Vector2()
# Called when the node enters the scene tree for the first time.
func _ready():
	var tiles = """..............................
*************************%****
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
.%............................
..............................
..............@..............."""
	load_tiles(tiles)
	replace_tiles()

const correspondance = {
	'%' : 'apple',
	'#' : 'wall',
	'@' : 'normal',
	'*' : 'boulder',
	'.' : 'grass'
}

func load_tiles(string):
	$TileMap.clear()
	var x = 1
	var y = 1
	var last_x = 0
	X_MIN = 0
	Y_MIN = 0
	for element in string:
		if(element == "\n"):
			x = 1
			y += 1
		else:
			map.set_cell(x, y, tileset.find_tile_by_name(correspondance[element]))
			x += 1
		last_x = max(last_x, x)
	X_MAX = last_x+1
	Y_MAX = y+2

func export_map():
	var dicted = []
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var cell = Vector2(x, y)
			var id = map.get_cellv(cell)
			dicted.append(id)
	return dicted

func replace_tiles():
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var cell = Vector2(x, y)
			var id = map.get_cellv(cell)
			if id == -1:
				map.set_cellv(cell, map.tile_set.find_tile_by_name("wall"))
			elif map.tile_set.tile_get_name(id) == "normal":
				character_position = cell

func get_entity_name(id):
	var result = "empty"
	if id != -1:
		result = tileset.tile_get_name(id)
	return result

func get_at(cell):
	return tileset.tile_get_name(map.get_cellv(cell))

func tick_next_step():
	timer.start()

func compute_next_step():
	var direction = desired_input
	desired_input = Vector2.ZERO
	var state = export_map()
	var cells = map.get_used_cells()
	cells.sort()
#	print("Start")
	if direction != Vector2.ZERO:
		var new_position = character_position + direction
		var target = get_at(new_position)
		var current = get_at(character_position)
		if current == "normal":
			if target in ["empty", 'apple', 'grass']:
				map.set_cellv(character_position, tileset.find_tile_by_name("empty"))
				map.set_cellv(new_position, tileset.find_tile_by_name("normal"))
				character_position = new_position
			elif target == "boulder":
				if(direction.y == 0):
					var empty_space_next = new_position + direction
					if get_at(empty_space_next) == "empty":
						map.set_cellv(character_position, tileset.find_tile_by_name("empty"))
						map.set_cellv(empty_space_next, tileset.find_tile_by_name("boulder"))
						map.set_cellv(new_position, tileset.find_tile_by_name("normal"))
						character_position = new_position
			return false
	else:
		for y in range(Y_MAX, Y_MIN, -1):
			for x in range(X_MIN, X_MAX):
				var cell = Vector2(x, y)
				var id = map.get_cellv(cell)
				if id == -1:
					continue
				var next_cell = cell + Vector2.DOWN
				var id_under = map.get_cellv(next_cell)
				var under = get_entity_name(id_under)
				var entity = tileset.tile_get_name(id)
				var right_of = cell + Vector2.RIGHT
				var left_of = cell + Vector2.LEFT
	#			print("Handling : ", entity, " - ", cell)
	#			print("Under is : ", under, " - ", next_cell)
				if entity == "boulder":
					if under == "empty":
						map.set_cellv(cell, tileset.find_tile_by_name("falling_boulder"))
						entity = "falling_boulder"
				if entity == "falling_boulder":
					if under == "empty":
						map.set_cellv(cell, tileset.find_tile_by_name("empty"))
						map.set_cellv(next_cell, tileset.find_tile_by_name("falling_boulder"))
					elif under == "boulder":
						var next_cell_right = cell + Vector2.DOWN + Vector2.RIGHT
						var next_cell_left = cell + Vector2.DOWN + Vector2.LEFT
						var under_left = get_at(next_cell_left)
						var under_right = get_at(next_cell_right)
						if under_left == "empty" and get_at(left_of) == "empty":
							map.set_cellv(cell, tileset.find_tile_by_name("empty"))
							map.set_cellv(next_cell_left, tileset.find_tile_by_name("falling_boulder"))
						elif under_right == "empty" and get_at(right_of) == "empty":
							map.set_cellv(cell, tileset.find_tile_by_name("empty"))
							map.set_cellv(next_cell_right, tileset.find_tile_by_name("falling_boulder"))
						else:
							map.set_cellv(cell, tileset.find_tile_by_name("boulder"))
					elif under in ["wall", "grass"]:
						map.set_cellv(cell, tileset.find_tile_by_name("boulder"))
					elif under == "normal":
						map.set_cellv(next_cell, tileset.find_tile_by_name("lost"))
						return true
					return false
	var state2 = export_map()
	return state == state2

func _on_Timer_timeout():
	can_move = false
	if !compute_next_step():
		timer.start()
	else:
		can_move = true

func _input(event):
	var input = Vector2()
	input.x = Input.get_axis("ui_left", "ui_right")
	if input.x == 0:
		input.y = Input.get_axis("ui_up", "ui_down")
	if can_move:
		desired_input = input
		tick_next_step()
