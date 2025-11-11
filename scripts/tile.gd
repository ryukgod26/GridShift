extends Button

signal tile_pressed(number)
signal slide_completed(number)

var number = 0

@onready var number_label = $NumberLabel
@onready var sprite_region = $SpriteRegion

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("tile_pressed", number)


func slide_to(new_position, duration):
	var tween = create_tween()
	tween.tween_property(self, "position", new_position, duration)\
		 .set_trans(Tween.TRANS_QUART)\
		 .set_ease(Tween.EASE_OUT)
	

	tween.finished.connect(_on_slide_finished)

func _on_slide_finished():

	emit_signal("slide_completed", number)


func set_number_visible(state: bool):
	if number_label:
		number_label.visible = state


func set_sprite(value: int, grid_size: int, tile_px_size: float):
	
	size = Vector2(tile_px_size, tile_px_size)
	
	var tex = $SpriteRegion.texture
	if not tex:
		return 


	var source_image_size = tex.get_size()
	var region_size = source_image_size / grid_size

	var atlas_coords = Vector2(value % grid_size, floor(value / grid_size))


	var new_region = Rect2()
	new_region.position = atlas_coords * region_size
	new_region.size = region_size

	sprite_region.texture_region = new_region
	
	sprite_region.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
