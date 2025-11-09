extends Control

@export var tsize := 4
@export var tile_size := 80
@export var tile_sceme: PackedScene
@export var slide_duration := 0.15

enum GAME_STATE{
	NOT_STARTED,
	STARTED,
	WON,
	LOSE
} 
var board := []
var tiles := []
var empty := Vector2()
var is_animating := false
var tiles_animating := 0

var move_count := 0
var number_visible := true
var background_texture = null
var game_state := GAME_STATE.NOT_STARTED

signal game_started
signal game_won
signal  moves_updated

func _ready() -> void:
	tile_size = floor(size.x / tsize)
	set_size(Vector2(tile_size*tsize,tile_size*tsize))
	gen_board()

func  _process(_delta: float) -> void:
	var is_pressed = true
	var dir = Vector2.ZERO
	
	if Input.is_action_just_pressed("move_left"):
		dir.x = -1
	elif  Input.is_action_just_pressed("move_right"):
		dir.x = 1
	elif Input.is_action_just_pressed("move_up"):
		dir.y = -1
	elif  Input.is_action_just_pressed("move_down"):
		dir.y = 1
	else :
		is_pressed = false
	if is_pressed:
		empty = value_to_grid(0)
		
		var nr = empty.y + dir.y
		var nc = empty.x + dir.x
		if nr == -1 or nc == -1 or nr >= tsize or nc >= tsize:
			return
		var tile_pressed = board[nr][nc]
		print(tile_pressed)
		_on_Tile_pressed(tile_pressed)

func gen_board():
	var value = 1
	board = []
	for r in range(tsize):
		board.append([])
		for c in range(tsize):
			#Choosing Which should be empty cell
			if (value == tsize*tsize):
				board[r].append(0)
				empty = Vector2(c,r)
			else:
				board[r].append(value)
				
				#Generating a new Tile
				var tile = tile_sceme.instantiate()
				tile.position = Vector2(c * tile_size,r * tile_size)
				#tile.text = value
				if background_texture:
					tile.texture = background_texture
				tile.set_sprite(value-1,tsize,tile_size)
				tile.set_number_visible(number_visible)
				tile.tile_pressed.connect(_on_Tile_pressed)
				tile.slide_completed.connect(_on_Tile_slide_completed)
				add_child(tile)
				tiles.append(tile)
			value +=1 

func is_game_solved() -> bool:
	var count = 1
	for r in range(tsize):
		for c in range(tsize):
			if(board[r][c] != count):
				if r == c and c == tsize - 1 and board[r][c] == 0:
					return true
				else:
					return false
			count += 1
	return true

func print_board() -> void:
	print('------board------')
	for r in range(tsize):
		var row = ''
		for c in range(tsize):
			row += str(board[r][c]).pad_zeros(2) + ' '
		print(row)

func value_to_grid(value):
	for r in range(tsize):
		for c in range(tsize):
			if board[r][c] == value:
				return Vector2(c,r)
	return null

func get_tile_by_value(value):
	for tile in tiles:
		if str(tile.number) ==  str(value):
			return tile
	return null

func _on_Tile_pressed(number):
	if is_animating:
		return
	
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
	
	var tile = value_to_grid(number)
	empty = value_to_grid(0)
	
	if tile.x != empty.x and tile.y != empty.y:
		return
	var dir = Vector2(sign(tile.x - empty.x),sign(tile.y - empty.y))
	var start = Vector2(min(tile.x,empty.x),min(tile.y,empty.y))
	var end = Vector2(max(tile.x,empty.x),max(tile.y,empty.y))
	
	for r in range(end.y,start.y-1,-1):
		for c in range(end.x,start.x-1,-1):
			if board[r][c] == 0:
				continue
			var object: TextureButton = get_tile_by_value(board[r][c])
			object.slide_to((Vector2(c,r) - dir) * tile_size,slide_duration)
			is_animating = true
			tiles_animating += 1

	var old_board = board.duplicate(true)
	if tile.y == empty.y:
		if dir.x == -1:
			board[tile.y] = slide_row(tile.y,1,start.x)
		else :
			board[tile.y] = slide_row(tile.y,-1,end.x)
	
	if tile.x == empty.x:
		var col = []
		for r in range(tsize):
			col.append(board[r][tile.x])
		if dir.y == -1:
			col = slide_column(col,1,start.y)
		else:
			col = slide_column(col,-1,end.y)
		for r in range(tsize):
			board[r][tile.x] = col[r]
	
	var moves_made = 0
	for r in range(tsize):
		for c in range(tsize):
			if old_board[r][c] != board[r][c]:
				moves_made += 1
	move_count = moves_made -1
	emit_signal("moves_updated",move_count)
	
	var is_solved = is_game_solved()
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
		for j in range(i+1,tsize*tsize):
			if flat[i] > flat[j] and flat[j] != 0:
				parity += 1
	if grid_width % 2 == 0:
		if blank_row % 2 == 0:
			return parity % 2 == 0
		else :
			return parity %2 != 0
	else:
		return parity % 2 == 0

func _on_Tile_slide_completed(_number):
	tiles_animating -= 1
	if tiles_animating == 0:
		is_animating = false

func scramble_board():
	reset_board()
	
	var temp_flat_board =[]
	for i in range((tsize*tsize) - 1,-1,-1):
		temp_flat_board.append(i)
	randomize()
	temp_flat_board.shuffle()
	
	var is_solvable = is_board_solvable(temp_flat_board)
	while not is_solvable:
		randomize()
		temp_flat_board.shuffle()
		is_solvable = is_board_solvable(temp_flat_board)
	for r in range(tsize):
		for c in range(tsize):
			board[r][c] = temp_flat_board[r*tsize + c]
			if board[r][c] != 0:
				set_tile_position(r,c,board[r][c])
	empty = value_to_grid(0)

func set_tile_position(r: int,c: int, val: int):
	var object: TextureButton = get_tile_by_value(val)
	object.set_position(Vector2(c,r) * tile_size)

func reset_board():
	reset_move_count()
	board = []
	for r in range(tsize):
		board.append([])
		for c in range(tsize):
			board[r].append(r*tsize + c +1)
			if r*tsize + c + 1 == tsize*tsize:
				board[r][c] = 0
			else:
				set_tile_position(r,c,board[r][c])
	empty = value_to_grid(0)

func reset_move_count():
	move_count = 0
	emit_signal("moves_updated", move_count)

func slide_row(row, dir, limiter):
	var empty_index = row.find(0)
	if dir == 1:
		#Toward Right
		var start = row.slice(0,limiter)
		start.pop_back()
		var pre = row.slice(limiter,empty_index)
		pre.pop_back()
		var post = row.slice(empty_index,row.size())
		post.pop_front()
		return start + [0] + pre + post
	else:
		#Toward Left
		var pre = row.slice(0,empty_index)
		pre.pop_back()
		var post = row.slice(empty_index,limiter)
		post.pop_front()
		var end = row.slice(limiter,row.size() - 1)
		end.pop_front()
		return pre + post + [0] + end

func slide_column(col,dir,limiter):
	var empty_index = col.find(0)
	
	if dir == 1:
		#Slide Down
		var start = col.slice(0,limiter)
		start.pop_back()
		var pre = col.slice(limiter,empty_index)
		pre.pop_back()
		var post = col.slice(empty_index,col.size() - 1)
		post.pop_front()
		return start + [0] + pre + post
	else:
		#Slide up
		var pre = col.slice(0, empty_index)
		pre.pop_back()
		var post = col.slice(empty_index, limiter)
		post.pop_front()
		var end = col.slice(limiter, col.size() - 1)
		end.pop_front()
		return pre + post + [0] + end
 
func set_tile_numbers(state):
	number_visible = state
	for tile in tiles:
		tile.set_number_visible(state)

func update_size(new_size):
	tsize = int(new_size)
	print('updating board size ', tsize)

	tile_size = floor(get_size().x / tsize)
	for tile in tiles:
		tile.queue_free()
	tiles = []
	gen_board()
	game_state = GAME_STATE.NOT_STARTED
	reset_move_count()

func update_background_texture(texture):
	background_texture = texture
	for tile in tiles:
		tile.set_sprite_texture(texture)
		tile.update_size(size, tile_size)
