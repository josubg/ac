extends TextureRect

var agent_id

func _get_drag_data(position):
	var data = {
		"agent_id": agent_id,
		"texture": texture
	}

	# Crea un control visual que servirá como "preview" durante el arrastre
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = texture
	preview.custom_minimum_size = Vector2(64, 64)  # opcional
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	set_drag_preview(preview)

	return data
