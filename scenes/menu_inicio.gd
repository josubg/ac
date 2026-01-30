extends Control

@export var mouse_parallax_enabled : bool = true
@export var mouse_parallax_strength : Vector2 = Vector2(200, 0) # px max offset
@export var mouse_smooth_speed : float = 2.0

# Comportamiento de borde
@export var edge_threshold : float = 0.99   # porcentaje del semiancho/semialto (0..1) para empezar a snapear
@export var snap_to_edge : bool = true     # si true, cuando el ratón supere edge_threshold, fijamos al borde
@export var max_rel : float = 0.98         # máximo relativo permitido (clamp en [-max_rel, max_rel])


@onready var parallax : Parallax2D = $CanvasLayer/Parallax2D
func _process(delta: float) -> void:
	if not mouse_parallax_enabled:
		return

	var vp_size = get_viewport_rect().size
	if vp_size.x == 0 or vp_size.y == 0:
		return

	var center = vp_size * 0.5
	var mpos = get_viewport().get_mouse_position()
	# rel en torno a [-1,1]
	var rel = Vector2()
	rel.x = (mpos.x - center.x) / center.x
	rel.y = (mpos.y - center.y) / center.y

	# Clamp absoluto para evitar valores locos (p. ej. monitores ultra-wide o multi-monitor)
	rel.x = clamp(rel.x, -max_rel, max_rel)
	rel.y = clamp(rel.y, -max_rel, max_rel)

	# Si snap_to_edge y el ratón está fuera del threshold, fijamos rel al borde (1 o -1)
	if snap_to_edge:
		if abs(rel.x) >= edge_threshold:
			rel.x = sign(rel.x) * 1.0
		if abs(rel.y) >= edge_threshold:
			rel.y = sign(rel.y) * 1.0

	# Ahora calculamos el target offset en px usando mouse_parallax_strength
	var target_offset = Vector2(rel.x * mouse_parallax_strength.x, rel.y * mouse_parallax_strength.y)

	# Finalmente, suavizamos la transición (a menos que estemos snappeando: si rel==±1 y queremos fijarlo instantáneo, se puede forzar)
	var smoothing = clamp(mouse_smooth_speed * delta, 0.0, 1.0)
	# Si estamos en snap y en borde, podemos setear inmediatamente para que parezca "pegado"
	if snap_to_edge and (abs(rel.x) == 1.0 or abs(rel.y) == 1.0):
		parallax.scroll_offset = target_offset
	else:
		parallax.scroll_offset = parallax.scroll_offset.lerp(target_offset, smoothing)


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_credits_button_pressed() -> void:
	$CreditosCanvas.visible = true


func _on_new_game_button_pressed() -> void:
	GameManager.start_game()
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if $CreditosCanvas.visible:
				$CreditosCanvas.visible = false
			else:
				get_tree().quit()


func _on_button_pressed() -> void:
	$CreditosCanvas.visible = false
