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
	check_tiles()
	states = [export_map()]
	history = 1

var history = 0

func check_tiles():
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var cell = Vector2(x, y)
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

func load_map(state_map : Array):
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var cell = Vector2(x, y)
			var tile = state_map.pop_front()
			map.set_cellv(cell, tile)
	check_tiles()

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

enum STATE{
	COMPUTE,
	SAVE,
	PLAYER_INPUT,
	MOVE_PLAYER,
	WIN,
	LOSS
}

var current_state = STATE.COMPUTE

func compute_next_frame_boulder(cell : Vector2):
	var under = cell + Vector2.DOWN
	if get_at(under) == "empty":
		set_at(cell, "falling_boulder")

func switch_state(new_state):
	if current_state != new_state:
		if new_state == STATE.LOSS:
			SoundManager.play("loss")
		current_state = new_state

func compute_next_frame_faling_boulder(cell : Vector2):
	var under = cell + Vector2.DOWN
	var entity = get_at(under)
	if entity == "player":
		set_at(character_position, "lost")
		switch_state(STATE.LOSS)
	elif entity == "empty":
		swap(cell, under)
	elif entity == "boulder":
		var left = cell + Vector2.LEFT
		var under_left = left + Vector2.DOWN
		var right = cell + Vector2.RIGHT
		var under_right = right + Vector2.DOWN
		if test_right_first:
			if get_at(right) == "empty" and get_at(under_right) in ["empty", "player"]:
				swap(cell, right)
			elif get_at(left) == "empty" and get_at(under_left) in ["empty", "player"]:
				swap(cell, left)
			else:
				set_at(cell, "boulder")
		else:
			if get_at(left) == "empty" and get_at(under_left) in ["empty", "player"]:
				swap(cell, left)
			elif get_at(right) == "empty" and get_at(under_right) in ["empty", "player"]:
				swap(cell, right)
			else:
				set_at(cell, "boulder")
		SoundManager.play("boulder")
	else:
		set_at(cell, "boulder")
		SoundManager.play("boulder")

func compute_next_frame():
	var current_map = export_map()
	for y in range(Y_MAX, Y_MIN, -1):
		for x in range(X_MIN, X_MAX):
			var cell = Vector2(x, y)
			var current_entity = get_at(cell)
			if current_entity == "boulder":
				compute_next_frame_boulder(cell)
			elif current_entity == "falling_boulder":
				compute_next_frame_faling_boulder(cell)
				return
	var finished_map = export_map()
	if(current_map == finished_map):
		switch_state(STATE.SAVE)

var states = []

func load_state():
	var current_state = export_map()
	var state = states[-1]
	while state == current_state and len(states) > 1:
		print("Again !")
		state = states.pop_back()
	load_map([] + state)

func save_state():
	var state = export_map()
	if states[-1] != state:
		states.append(state)

func load_frame():
	load_state()
	switch_state(STATE.PLAYER_INPUT)

func save_frame():
	save_state()
	switch_state(STATE.PLAYER_INPUT)

var requested_direction = Vector2.ZERO

func ask_player():
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if Input.is_action_just_pressed("ui_cancel"):
		load_frame()
	elif direction != Vector2.ZERO:
		if direction.x != 0 and direction.y != 0:
			direction.y = 0
		switch_state(STATE.MOVE_PLAYER)
		requested_direction = direction

var test_right_first = false

func move_player():
	var current_position = character_position
	var target_position = character_position + requested_direction
	var target = get_at(target_position)
	if(target in ["empty", "apple", "grass"]):
		set_at(current_position, "empty")
		set_at(target_position, "player")
		character_position = target_position
	elif requested_direction.y == 0 and target == "boulder":
		var supertarget_position = target_position + requested_direction
		var supertarget = get_at(supertarget_position)
		if supertarget == "empty":
			set_at(target_position, "player")
			set_at(supertarget_position, "boulder")
			set_at(current_position, "empty")
			character_position = target_position
	if character_position != current_position:
		test_right_first = (requested_direction.x > 0)
#	else:
#		SoundManager.play("no")
	switch_state(STATE.COMPUTE)


func _physics_process(delta):
	if current_state == STATE.COMPUTE:
		compute_next_frame()
	elif current_state == STATE.SAVE:
		save_frame()
	elif current_state == STATE.PLAYER_INPUT:
		ask_player()
	elif current_state == STATE.MOVE_PLAYER:
		move_player()
	elif current_state == STATE.LOSS:
		if Input.is_action_just_pressed("ui_cancel"):
			load_frame()
	else:
		print("Unhandled case : ", current_state)
