class_name DragPreview
## Vista previa del retrato que se arrastra: tarjeta enmarcada en oro, con sombra,
## un poco ladeada y centrada bajo el cursor (no en su esquina).

const FRAME := preload("res://assets/ui/textures/marco_dorado.png")
const CARD_SIZE := Vector2(116, 136)


static func build(texture: Texture2D) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 1000

	var shadow := ColorRect.new()
	shadow.color = Color(0.05, 0.03, 0.02, 0.45)
	shadow.size = CARD_SIZE
	shadow.position = -CARD_SIZE * 0.5 + Vector2(7, 9)
	shadow.pivot_offset = CARD_SIZE * 0.5
	shadow.rotation = deg_to_rad(-4.0)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shadow)

	var card := Control.new()
	card.clip_contents = true
	card.size = CARD_SIZE
	card.position = -CARD_SIZE * 0.5
	card.pivot_offset = CARD_SIZE * 0.5
	card.rotation = deg_to_rad(-4.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)

	# El retrato se amplía un 20 % para ocultar el borde pintado en la ilustración.
	var portrait := TextureRect.new()
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size = CARD_SIZE * 1.2
	portrait.position = -CARD_SIZE * 0.1
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)

	var frame := NinePatchRect.new()
	frame.texture = FRAME
	frame.patch_margin_left = 22
	frame.patch_margin_top = 22
	frame.patch_margin_right = 22
	frame.patch_margin_bottom = 22
	frame.size = CARD_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(frame)
	return root
