extends Panel
class_name  FactionProgress

@export var faction_signal : String
@export var faction_name : String
@export var faction_inverse : bool

func _ready():
	$FactionLabel.text = faction_name
	Global.connect(self.faction_signal, _on_faction_changed)
	

func _on_faction_changed(descontento):
	$Bar.value = descontento
	_update_color(descontento)
	
func _update_color(descontento: float) -> void:
	var color_ratio = descontento / 100.0
	var color = Color.GREEN.lerp(Color.RED, color_ratio)
	if not faction_inverse:
		color = Color.RED.lerp(Color.GREEN, color_ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	$Bar.add_theme_stylebox_override("background", style)
	print("Color cambiado a ",color)
