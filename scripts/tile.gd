extends TextureButton

var number
@onready var sprite = $Sprite
var tween = create_tween()

signal tile_pressed
signal slide_completed

func set_text(new_muber):
	number = new_muber
	$Number/Label.text = str(new_muber)

func set_sprite(new_frame,size,tile_size):
	update_size(size,tile_size)
	
	$Sprite.hframes = size
	$Sprite.vframes = size
	$Sprite.frame =  new_frame

func update_size(tsize,tile_size):
	var new_size = Vector2(tile_size,tile_size)
	
	set_size(new_size)
	$Number.set_size(new_size)
	$Number/ColorRect.set_size(new_size)
	$Number/Label.set_size(new_size)
	$Panel.set_size(new_size)
	
	var to_scale = tsize *(new_size / $Sprite.texture.get_size())
	$Sprite.scale = to_scale

func set_sprite_texture(new_texture):
	sprite.texture = new_texture

func slide_to(new_position,duration):
	tween.tween_property(self,"position",new_position,duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func set_number_visible(state):
	$Number.visible = state

func _on_pressed() -> void:
	emit_signal("tile_pressed",number)

func _on_tween_finished():
	emit_signal("slide_completed",number)
