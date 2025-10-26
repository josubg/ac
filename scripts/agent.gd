extends Panel
class_name Agent


@export var full_name: String
@export var selected: Texture2D
@export var unselected: Texture2D
@export var biografy: String

@export var noble: bool
@export var cura: bool
@export var malechor: bool

 

var assigned: bool :
	set(value):
		assigned = value
		if value:
			$Portrait.texture = self.unselected
		else:
			$Portrait.texture = self.selected


func _ready() -> void:
	self.assigned = false


func _get_drag_data(_position):
	if self.assigned:
		print("Draging Null")
		return null
	# Crea un control visual que servirá como "preview" durante el arrastre
	print("Draging Agent")
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = $Portrait.texture
	preview.custom_minimum_size = Vector2(64, 64)  # opcional
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	set_drag_preview(preview)
	return self
