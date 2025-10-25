extends ProgressBar


func _ready():
	Global.
	.connect(_on_influencia_changed)
	

func _on_influencia_changed(value):
	self.value = value
	_update_color(value)
	
func _update_color(pontency: float) -> void:
	var ratio = pontency / 100.0
	var color = Color.RED.lerp(Color.GREEN, ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	$".".add_theme_stylebox_override("background", style)
	print("Color cambiado a ",color)
