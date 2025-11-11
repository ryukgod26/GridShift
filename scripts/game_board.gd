extends Node2D

const TileScene = preload("res://scenes/Interface/tile.tscn")

const TEX_START = preload("res://assets/start.png")
const TEX_END = preload("res://assets/end.png")
const TEX_PATH = preload("res://assets/path.png")
const TEX_BLOCKER = preload("res://assets/blocker.png")


const GRID_WIDTH = 7
const GRID_HEIGHT = 7
const TILE_SIZE = 64 


var grid_data = []

var tile_nodes = []


var is_dragging = false
var drag_start_pos = Vector2.ZERO
var dragged_object = null 
var drag_delta = Vector2.ZERO



func _ready():

	var initial_layout = [
		["s", "p", "b", "b", "b", "p", "p"],
		["p", "p", "p", "b", "p", "p", "p"],
		["p", "b", "p", "p", "p", "b", "p"],
		["p", "b", "p", "e", "p", "b", "p"],
		["p", "b", "p", "p", "p", "b", "p"],
		["p", "p", "p", "b", "p", "p", "p"],
		["p", "p", "b", "b", "b", "p", "p"]
	]
	
	initialize_board(initial_layout)
	
	get_node("UI/ResetButton").pressed.connect(_on_reset_pressed)


func initialize_board(layout):

	grid_data = []
	tile_nodes = []
	for child in get_children():
		child.queue_free()


	grid_data = layout.duplicate(true)

	tile_nodes.resize(GRID_HEIGHT)
	for y in range(GRID_HEIGHT):
		tile_nodes[y] = []
		tile_nodes[y].resize(GRID_WIDTH)
		for x in range(GRID_WIDTH):
			var tile_type = grid_data[y][x]
			var new_tile = TileScene.instantiate()
			
			new_tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			

			set_tile_texture(new_tile, tile_type)

			add_child(new_tile)
			tile_nodes[y][x] = new_tile



func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:

				is_dragging = true
				drag_start_pos = get_global_mouse_position()
				drag_delta = Vector2.ZERO
				

				var grid_pos_vec = get_local_mouse_position() / TILE_SIZE
				var grid_pos = Vector2i(int(grid_pos_vec.x), int(grid_pos_vec.y))
				
				if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH or grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:

					is_dragging = false
					dragged_object = null
					return
				

				dragged_object = {"type": null, "index": -1, "start_coord": grid_pos}
				
			else:

				if is_dragging:
					is_dragging = false
					

					var slide_amount = 0
					if dragged_object.type == "row":
						slide_amount = int(round(drag_delta.x / TILE_SIZE))
						shift_row(dragged_object.index, slide_amount)
					elif dragged_object.type == "col":
						slide_amount = int(round(drag_delta.y / TILE_SIZE))
						shift_col(dragged_object.index, slide_amount)
					

					redraw_board()
					

					check_win_condition()

	if event is InputEventMouseMotion and is_dragging:

		drag_delta = event.position - drag_start_pos
		

		if dragged_object.type == null and drag_delta.length() > 10: 
			if abs(drag_delta.x) > abs(drag_delta.y):
				dragged_object.type = "row"
				dragged_object.index = dragged_object.start_coord.y 
			else:
				dragged_object.type = "col"
				dragged_object.index = dragged_object.start_coord.x 
		

		update_visual_drag()



func update_visual_drag():
	var grid_size_px = Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
	
	if dragged_object.type == "row":
		var y = dragged_object.index
		for x in range(GRID_WIDTH):
			var base_x = x * TILE_SIZE

			var wrapped_x = fmod(base_x + drag_delta.x, grid_size_px.x)
			if wrapped_x < 0:
				wrapped_x += grid_size_px.x
			tile_nodes[y][x].position.x = wrapped_x
			
	elif dragged_object.type == "col":
		var x = dragged_object.index
		for y in range(GRID_HEIGHT):
			var base_y = y * TILE_SIZE

			var wrapped_y = fmod(base_y + drag_delta.y, grid_size_px.y)
			if wrapped_y < 0:
				wrapped_y += grid_size_px.y
			tile_nodes[y][x].position.y = wrapped_y


func shift_row(row_index, amount):
	if amount == 0: return
	
	var row = grid_data[row_index]
	var new_row = []
	new_row.resize(GRID_WIDTH)
	
	for i in range(GRID_WIDTH):
		var new_index = (i - amount) % GRID_WIDTH
		if new_index < 0:
			new_index += GRID_WIDTH
		new_row[i] = row[new_index]
		
	grid_data[row_index] = new_row

func shift_col(col_index, amount):
	if amount == 0: return
	
	var col = []
	for y in range(GRID_HEIGHT):
		col.append(grid_data[y][col_index])
	
	var new_col = []
	new_col.resize(GRID_HEIGHT)
	
	for i in range(GRID_HEIGHT):
		var new_index = (i - amount) % GRID_HEIGHT
		if new_index < 0:
			new_index += GRID_HEIGHT
		new_col[i] = col[new_index]
		
	for y in range(GRID_HEIGHT):
		grid_data[y][col_index] = new_col[y]


func redraw_board():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):

			tile_nodes[y][x].position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			

			var tile_type = grid_data[y][x]
			set_tile_texture(tile_nodes[y][x], tile_type)


func check_win_condition():

	var start_pos = null
	var end_pos = null
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid_data[y][x] == "s":
				start_pos = Vector2i(x, y)
			elif grid_data[y][x] == "e":
				end_pos = Vector2i(x, y)
	
	if start_pos == null or end_pos == null:
		print("Error: No start or end tile found!")
		return


	if start_pos.distance_to(end_pos) == 1:
		print("YOU WIN! (Simple Check)")
		get_node("UI/WinMessage").visible = true
	else:
		get_node("UI/WinMessage").visible = false
	

func set_tile_texture(tile_node, tile_type):
	var sprite = tile_node.get_node("Sprite2D")
	match tile_type:
		"s":
			sprite.texture = TEX_START
		"e":
			sprite.texture = TEX_END
		"p":
			sprite.texture = TEX_PATH
		"b":
			sprite.texture = TEX_BLOCKER
		_:

			sprite.texture = TEX_BLOCKER 
func _on_reset_pressed():
	var initial_layout = [
		["s", "p", "b", "b", "b", "p", "p"],
		["p", "p", "p", "b", "p", "p", "p"],
		["p", "b", "p", "p", "p", "b", "p"],
		["p", "b", "p", "e", "p", "b", "p"],
		["p", "b", "p", "p", "p", "b", "p"],
		["p", "p", "p", "b", "p", "p", "p"],
		["p", "p", "b", "b", "b", "p", "p"]
	]
	initialize_board(initial_layout)
	get_node("/root/Main/UI/WinMessage").visible = false
