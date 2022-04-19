extends Node2D

onready var map = $LevelMap
onready var tileset = map.tile_set

var can_move = true
var desired_input = Vector2.ZERO

var X_MIN = 0
var X_MAX = 23
var Y_MIN = 0
var Y_MAX = 23

const correspondance = {
	'%' : 'apple',
	'#' : 'wall',
	'@' : 'player',
	'*' : 'boulder',
	'!' : 'grass',
	'.' : 'empty'
}

var character_position = Vector2()
# Called when the node enters the scene tree for the first time.
func _ready():
	var tiles = """!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*************************%****
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
*%*%*%*%*%*%*%*%*%*%*%*%*%*%*%
%*%*%*%*%*%*%*%*%*%*%*%*%*%*%*
!%!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!@!!!!!!!!!!!!!!!"""
	var tilesd = """..............................
......*.......................
......*.......................
......*.......................
......*.......................
......*.......................
......*.......................
......*.......................
......*.......................
......*.......................
......@.......................
..............................
..............................
..............................
..............................
..............................
..............................
..............................
..............................
..............................
.............................."""
	load_tiles(tiles)

func load_tiles(string):
	map.clear()
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
	for xi in range(X_MIN, X_MAX):
		for yi in range(Y_MIN, Y_MAX):
			var cell = Vector2(xi, yi)
			var id = map.get_cellv(cell)
			if id == -1:
				map.set_cellv(cell, map.tile_set.find_tile_by_name("wall"))
			elif map.tile_set.tile_get_name(id) == "player":
				character_position = cell

func export_map():
	var dicted = []
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var cell = Vector2(x, y)
			var id = map.get_cellv(cell)
			dicted.append(id)
	return dicted

func get_at(cell):
	var result = "empty"
	var id = map.get_cellv(cell)
	if id != -1:
		result = tileset.tile_get_name(id)
	return result

func set_at(cell : Vector2, tile : String):
	map.set_cellv(cell, tileset.find_tile_by_name(tile))

func swap(original_cell : Vector2, target_cell : Vector2):
	var id = map.get_cellv(original_cell)
	map.set_cellv(original_cell, map.get_cellv(target_cell))
	map.set_cellv(target_cell, id)

func compute_next_step_boulder(position : Vector2, next_state : String):
	if get_at(position) == "boulder":
		var under = position + Vector2.DOWN
		var under_entity = get_at(under)
		if under_entity == "empty":
			set_at(position, "falling_boulder")
			return "compute"
	return next_state

func compute_next_step_falling_boulder(position : Vector2, next_state : String):
	if get_at(position) == "falling_boulder":
		var under = position + Vector2.DOWN
		var under_entity = get_at(under)
		if under_entity == "empty":
			swap(position, under)
		elif under_entity in ["grass", "wall"]:
			set_at(position, "boulder")
		elif under_entity == "boulder":
			var under_right = under + Vector2.RIGHT
			var under_left = under + Vector2.LEFT
			var check_right = position + Vector2.RIGHT
			var check_left = position + Vector2.LEFT
			if get_at(check_left) == "empty" and get_at(under_left) == "empty":
				swap(position, under_left)
			elif get_at(check_right) == "empty" and get_at(under_right) == "empty":
				swap(position, under_right)
			else:
				set_at(position, "boulder")
		elif under_entity == "player":
			set_at(position, "boulder")
			set_at(character_position, "lost")
			return "loss"
		return "compute"
	return next_state

func compute_next_step():
	var next_step = "computation_done"
	var current_state = export_map()
	for y in range(Y_MAX, Y_MIN, -1):
		for x in range(X_MIN, X_MAX):
			var cell = Vector2(x, y)
			var entity = get_at(cell)
			if entity == "falling_boulder":
				next_step = compute_next_step_falling_boulder(cell, next_step)
			elif entity == "boulder":
				next_step = compute_next_step_boulder(cell, next_step)
			if next_step in ["compute", "loss"]:
				return next_step
	if current_state != export_map():
		return "compute"
	return  next_step

func compute_player_step():
	if desired_input.length() == 0:
		return "player"
	var new_position = character_position + desired_input
	var target = get_at(new_position)
	var current = get_at(character_position)
	if current == "player":
		if target in ["empty", 'apple', 'grass']:
			set_at(new_position, "empty")
			swap(character_position, new_position)
			character_position = new_position
		elif target == "boulder":
			if(desired_input.y == 0):
				var empty_space_next = new_position + desired_input
				if get_at(empty_space_next) == "empty":
					set_at(new_position, "empty")
					set_at(empty_space_next, "boulder")
					swap(new_position, character_position)
					character_position = new_position
		return "compute"
	return "player"


var state = "compute"
var check_player = false	

func pop_back():
	pass

var history = []

func save():
	var sstate = {}
	var map_state = {}
	for i in map.get_used_cells():
		map_state[i] = map.get_cellv(i)
	sstate["map"] = map_state
	sstate["player"] = character_position
	history.push_back(sstate)
	print("State saved", len(history))

func pop_state():
	print("push : ", len(history))
	if len(history) > 0:
		var pstate = history.pop_back()
		character_position = pstate['player']
		map.clear()
		for i in pstate['map']:
			map.set_cellv(i, pstate['map'][i])
	return "player"

func _input(event):
	if state == "player":
		if Input.is_action_pressed("ui_cancel"):
			state = "restore"
		else:
			var input = Vector2()
			input.x = Input.get_axis("ui_left", "ui_right")
			if input.x == 0:
				input.y = Input.get_axis("ui_up", "ui_down")
			desired_input = input
			if desired_input != Vector2.ZERO:
				state = compute_player_step()
				desired_input = Vector2.ZERO
	elif state == "loss":
		if Input.is_action_just_released("ui_cancel"):
			state = "restore"

func _physics_process(delta):
	if state == "compute":
		state = compute_next_step()
	elif state == "computation_done":
		save()
		state = "player"
	elif state == "restore":
		state = pop_state()
