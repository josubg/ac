extends Label
## Bocadillo de diálogo: ajusta su alto al texto y crece hacia arriba desde `base_y`,
## para que la cola siga apuntando al retrato. Solo presentación: no toca la lógica.

@export var base_y := 700.0

var _texto := ""
var _ancho := -1.0


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or (text == _texto and size.x == _ancho):
		return
	_texto = text
	_ancho = size.x
	var caja := get_theme_stylebox("normal")
	var linea := get_line_height() + get_theme_constant("line_spacing")
	var alto := get_line_count() * linea + caja.get_minimum_size().y
	size = Vector2(size.x, alto)
	position.y = base_y - alto
