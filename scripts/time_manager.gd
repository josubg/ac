extends Node

@onready var current_time : float = 0.0
var descontento_up : float = 0
var paused: bool = false
var events: Array = []

func _process(delta):
	if paused:
		return
	current_time += delta / 60.0  # convierte segundos reales a minutos de juego
	_check_events()
	_check_descontento(delta)

func _check_events():
	pass  #TO-DO

func _check_descontento(delta):
	descontento_up += delta*10
	if descontento_up >= 60:
		descontento_up = 0
		Player.descontento += 1
