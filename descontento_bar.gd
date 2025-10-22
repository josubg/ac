extends ProgressBar

func _ready():
	Global.descontento_changed.connect(_on_descontento_changed)
	_on_descontento_changed(Global.descontento)

func _on_descontento_changed(value):
	self.value = value
	_update_color(value)
	
func _update_color(value: float) -> void:
	var ratio = value / 100.0
	var color = Color.GREEN.lerp(Color.RED, ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	$".".add_theme_stylebox_override("background", style)
	print("Color cambiado a ",color)
