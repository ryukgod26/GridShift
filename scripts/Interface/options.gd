extends Control

@onready var audio_scroll: HScrollBar = $VBoxContainer/Audio_Scroll

var volume:float = AudioServer.get_bus_volume_db(0)

func _ready() -> void:
	audio_scroll.value = volume

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Interface/main_menu.tscn")

func _on_audio_scroll_value_changed(value: float) -> void:
	volume = value
	AudioServer.set_bus_volume_db(0,volume-80)

func _on_resolution_item_selected(index: int) -> void:
	match  index:
		0:
			DisplayServer.window_set_size(Vector2i(1600,900))
		1:
			DisplayServer.window_set_size(Vector2i(1080,720))
		2:
			DisplayServer.window_set_size(Vector2i(1920,1080))


func _on_window_type_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_mute_toggled(toggled_on: bool) -> void:
	if toggled_on:
		AudioServer.set_bus_volume_db(0,-80)
	else:
		AudioServer.set_bus_volume_db(0,volume)
