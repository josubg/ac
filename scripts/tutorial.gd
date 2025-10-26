extends Control

func _ready():
	hide()  # Iniciamos ocultos
# Función para conectar el botón después de instanciar
func connect_close_button():
	var btn = $Button
	if btn:
		btn.pressed.connect(self.hide)
