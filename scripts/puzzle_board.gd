extends Control

@export var tsize := 4
@export var tile_size := 80
@export var tile_sceme: PackedScene
@export var slide_duration := 0.15

enum GAME_STATE {
	NOT_STARTED,
	STARTED,
	WON
}

var board := []
var tiles := []
var empty := Vector2()
var is_animating := false
var tiles_animating := 0

var move_count := 0
var number_visible := true
var background_texture: Texture2D = null # Type hint for clarity

var game_state := GAME_STATE.NOT_STARTED

signal game_started
signal game_won
signal moves_updated

func _ready():
	# Use 'size' property directly, not get_size()
	tile_size = floor(size.x / tsize)
	# Use 'size' property directly, not set_size()
	size = Vector2(tile_size * tsize, tile_size * tsize)
	
	gen_board()
	
	# Scramble the board on start, not on first click
	scramble_board()
	game_state = GAME_STATE.STARTED
	emit_signal('game_started')


func _process(_delta):
	var is_pressed = true
	var dir = Vector2.ZERO
	if (Input.is_action_just_pressed("move_left")):
		dir.x = -1
	elif (Input.is_action_just_pressed("move_right")):
		dir.x = 1
	elif (Input.is_action_just_pressed("move_up")):
		dir.y = -1
	elif (Input.is_action_just_pressed("move_down")):
		dir.y = 1
	else:
		is_pressed = false
		
	if is_pressed:
		empty = value_to_grid(0)

		var nr = empty.y + dir.y
		var nc = empty.x + dir.x
		if (nr == -1 or nc == -1 or nr >= tsize or nc >= tsize):
			return
		var tile_pressed = board[nr][nc]
		_on_Tile_pressed(tile_pressed)


func gen_board():
	var value = 1
	board = []
	for r in range(tsize):
		board.append([])
		for c in range(tsize):

			# choose which is empty cell
			if (value == tsize*tsize):
				board[r].append(0)
				empty = Vector2(c, r)
			else:
				board[r].append(value)

				# --- GODOT 4 CHANGES ---
				var tile = tile_sceme.instantiate() # Use .instantiate()
				tile.position = Vector2(c * tile_size, r * tile_size) # Use .position
				
				# This assumes your 'tile_scene' has a child Label node named "NumberLabel"
				tile.get_node("NumberLabel").text = str(value)
				# Store the number in the tile's script
				tile.number = value 
				
				if background_texture:
					# Use 'texture_normal' for TextureButton
					tile.texture_normal = background_texture 
				
				# Call the tile's custom setup function
				tile.set_sprite(value-1, tsize, tile_size)
				tile.set_number_visible(number_visible)
				
				# New signal connection syntax
				tile.tile_pressed.connect(_on_Tile_pressed)
				tile.slide_completed.connect(_on_Tile_slide_completed)
				
				add_child(tile)
				tiles.append(tile)

			value += 1

func is_board_solved():
	var count = 1
	for r in range(tsize):
		for c in range(tsize):
			if (board[r][c] != count):
				# This logic was slightly fixed for clarity
				if (r == tsize - 1 and c == tsize - 1 and board[r][c] == 0):
					return true
				else:
					return false
			count += 1
	# This case was never reached, but it is valid
	return true 

func print_board():
	print('------board------')
	for r in range(tsize):
		var row = ''
		for c in range(tsize):
			row += str(board[r][c]).pad_zeros(2) + ' '
		print(row)

func value_to_grid(value):
	for r in range(tsize):
		for c in range(tsize):
			if (board[r][c] == value):
				return Vector2(c, r)
	return null

func get_tile_by_value(value):
	for tile in tiles:
		if tile.number == value: # Compare int to int
			return tile
	return null

func _on_Tile_pressed(number):
	if is_animating:
		return

	# This logic is fine, but we'll restart if the game is won
	if game_state == GAME_STATE.NOT_STARTED:
		scramble_board()
		game_state = GAME_STATE.STARTED
		emit_signal('game_started')
		return
	
	if game_state == GAME_STATE.WON:
		game_state = GAME_STATE.STARTED
		reset_move_count()
		scramble_board()
		emit_signal('game_started')
		return

	var tile_pos = value_to_grid(number)
	empty = value_to_grid(0)

	if (tile_pos.x != empty.x and tile_pos.y != empty.y):
		return

	var dir = Vector2(sign(tile_pos.x - empty.x), sign(tile_pos.y - empty.y))

	# This logic is much simpler: just slide tiles between empty and the click
	if tile_pos.y == empty.y: # Horizontal slide
		var y = tile_pos.y
		var start_x = empty.x
		var end_x = tile_pos.x
		var slide_dir = -sign(dir.x) # Direction the *empty* space moves
		
		for x in range(start_x, end_x, slide_dir):
			var val = board[y][x + slide_dir]
			var object: TextureButton = get_tile_by_value(val)
			object.slide_to(Vector2(x, y) * tile_size, slide_duration)
			
			board[y][x] = val
			board[y][x + slide_dir] = 0
			
			is_animating = true
			tiles_animating += 1
			
	elif tile_pos.x == empty.x: # Vertical slide
		var x = tile_pos.x
		var start_y = empty.y
		var end_y = tile_pos.y
		var slide_dir = -sign(dir.y) # Direction the *empty* space moves

		for y in range(start_y, end_y, slide_dir):
			var val = board[y + slide_dir][x]
			var object: TextureButton = get_tile_by_value(val)
			object.slide_to(Vector2(x, y) * tile_size, slide_duration)

			board[y][x] = val
			board[y + slide_dir][x] = 0
			
			is_animating = true
			tiles_animating += 1

	move_count += 1
	emit_signal("moves_updated", move_count)

	# check win
	if tiles_animating == 0: # Only check for win if no tiles are moving
		var is_solved = is_board_solved()
		if is_solved:
			game_state = GAME_STATE.WON
			emit_signal("game_won")

func is_board_solvable(flat):
	var parity = 0
	var grid_width = tsize
	var row = 0
	var blank_row = 0
	for i in range(tsize*tsize):
		if i % grid_width == 0:
			row += 1

		if flat[i] == 0:
			blank_row = row
			continue

		for j in range(i+1, tsize*tsize):
			if flat[i] > flat[j] and flat[j] != 0:
				parity += 1

	if grid_width % 2 == 0:
		if blank_row % 2 == 0:
			return parity % 2 == 0
		else:
			return parity % 2 != 0
	else:
		return parity % 2 == 0

func scramble_board():
	reset_board()

	var temp_flat_board = []
	for i in range(tsize*tsize): # Simpler creation
		temp_flat_board.append(i)

	# No 'randomize()' needed in Godot 4
	temp_flat_board.shuffle()

	var is_solvable = is_board_solvable(temp_flat_board)
	while not is_solvable:
		temp_flat_board.shuffle()
		is_solvable = is_board_solvable(temp_flat_board)
	
	for r in range(tsize):
		for c in range(tsize):
			board[r][c] = temp_flat_board[r*tsize + c]
			if board[r][c] != 0:
				set_tile_position(r, c, board[r][c])
	empty = value_to_grid(0)


func reset_board():
	reset_move_count()
	board = []
	var count = 1
	for r in range(tsize):
		board.append(([]))
		for c in range(tsize):
			if (count == tsize * tsize):
				board[r].append(0)
			else:
				board[r].append(count)
				set_tile_position(r, c, count)
			count += 1
	empty = value_to_grid(0)

func set_tile_position(r: int, c: int, val: int):
	var object: TextureButton = get_tile_by_value(val)
	if object: # Add a check in case tile isn't found
		object.position = Vector2(c, r) * tile_size # Use .position

func _on_Tile_slide_completed(_number):
	tiles_animating -= 1
	if tiles_animating == 0:
		is_animating = false
		# Check for win *after* animation is done
		var is_solved = is_board_solved()
		if is_solved:
			game_state = GAME_STATE.WON
			emit_signal("game_won")

func reset_move_count():
	move_count = 0
	emit_signal("moves_updated", move_count)

func set_tile_numbers(state):
	number_visible = state
	for tile in tiles:
		tile.set_number_visible(state) # Call custom function on tile

func update_size(new_size):
	tsize = int(new_size)
	print('updating board size ', tsize)

	tile_size = floor(size.x / tsize) # use 'size'
	for tile in tiles:
		tile.queue_free()
	tiles = []
	gen_board()
	# Scramble the new board
	scramble_board()
	game_state = GAME_STATE.STARTED
	reset_move_count()
	emit_signal('game_started')


func update_background_texture(texture):
	background_texture = texture
	for tile in tiles:
		tile.texture_normal = texture # Use 'texture_normal'
		# Call 'set_sprite' again to update the region
		var value = tile.number - 1
		tile.set_sprite(value, tsize, tile_size)
