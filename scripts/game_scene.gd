extends Control

var is_started = false
var game_won:bool = false
var start_time
var current_time

@onready var board = $MarginContainer/VBoxContainer/GameView/Board
@onready var overlay = $MarginContainer/VBoxContainer/GameView/StartOverlay
@onready var overlay_text = $MarginContainer/VBoxContainer/GameView/StartOverlay/TextOverlay
@onready var move_value = $MarginContainer/VBoxContainer/StatsView/HBoxContainer/Moves/MoveValue
@onready var timer_value = $MarginContainer/VBoxContainer/StatsView/HBoxContainer/Time/TimeValue
@onready var anim_player = $AnimationPlayer

func _ready():
	overlay.visible = true

func _process(_delta):
	if is_started:
		current_time = Time.get_ticks_msec()
		var time_since_game_start = current_time - start_time
		timer_value.text = str(floor(time_since_game_start/1000)) + 's'
	else:
		if not game_won:
			timer_value.text = '0s'

func _on_Board_game_started():
	start_time= Time.get_ticks_msec()
	overlay.visible = false
	is_started = true
	game_won = false


func _on_Board_game_won():
	overlay_text.text = 'You Won!!! Want zto Play Again'
	overlay.visible = true
	is_started = false
	game_won = true


func _on_RestartButton_pressed():
	if not is_started:
		return
	board.reset_move_count()
	board.scramble_board()
	board.game_state = board.GAME_STATE.STARTED
	# 'OS' is now 'Time'
	start_time = Time.get_ticks_msec()
	is_started = true


func _on_Board_moves_updated(move_count):
	move_value.text = str(move_count)
