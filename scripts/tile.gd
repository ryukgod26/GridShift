extends Button

# This script must be attached to your 'tile_scene'
# Your 'tile_scene' root must be a Button
# It MUST have a child Label node named "NumberLabel"
# It MUST have a child TextureRect node named "SpriteRegion"

# These signals are emitted by this script
signal tile_pressed(number)
signal slide_completed(number)

# This variable is set by board.gd
var number = 0

# Get the child nodes
@onready var number_label = $NumberLabel
@onready var sprite_region = $SpriteRegion

func _ready():
	# Connect the button's built-in "pressed" signal
	# to our own function
	pressed.connect(_on_pressed)

func _on_pressed():
	# When pressed, emit our custom 'tile_pressed' signal
	# and send our number with it
	emit_signal("tile_pressed", number)

# --- Custom Functions (Called by board.gd) ---

# This function creates the slide animation
func slide_to(new_position, duration):
	var tween = create_tween()
	tween.tween_property(self, "position", new_position, duration)\
		 .set_trans(Tween.TRANS_QUART)\
		 .set_ease(Tween.EASE_OUT)
	
	# When the tween finishes, call '_on_slide_finished'
	tween.finished.connect(_on_slide_finished)

func _on_slide_finished():
	# When sliding is done, emit our custom 'slide_completed' signal
	emit_signal("slide_completed", number)


# This function shows/hides the number
func set_number_visible(state: bool):
	if number_label:
		number_label.visible = state

# This function "cuts" the piece from the main texture
func set_sprite(value: int, grid_size: int, tile_px_size: float):
	
	# 1. Set the size of this button control
	size = Vector2(tile_px_size, tile_px_size)
	
	# 2. Get the full puzzle image from the TextureRect
	var tex = $SpriteRegion.texture
	if not tex:
		return # No texture to cut up

	# 3. Calculate the size of one "region" from the source image.
	var source_image_size = tex.get_size()
	var region_size = source_image_size / grid_size

	# 4. Calculate the (x, y) coordinates of this tile in the grid
	var atlas_coords = Vector2(value % grid_size, floor(value / grid_size))

	# 5. Create the Rect2 for the region
	var new_region = Rect2()
	new_region.position = atlas_coords * region_size
	new_region.size = region_size

	# 6. Set the 'texture_region' property ON THE TEXTURERECT
	sprite_region.texture_region = new_region
	
	# 7. Set the stretch mode ON THE TEXTURERECT
	#    (This replaces 'texture_region_size' and 'stretch_mode')
	sprite_region.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
