extends Label
## Rótulo «En pausa» bajo la fecha del HUD: visible mientras el tiempo está detenido
## (ventanas, mensajes de la monja o menú de pausa).

func _process(_delta: float) -> void:
	visible = TimeManager.paused
