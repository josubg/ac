extends Node

@onready var current_time : float = 0.0
var descontento_up : float = 0
var paused: bool = false
var events: Array = []
var start_date = -10413788339

var dias = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo",]
var  meses =["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre",
 "Octubre", "Noviembre", "Diciembre"]
func run():
	self.set_process(true)
	self.current_time = 0
	self.paused= false
	
func _process(delta):
	if self.paused:
		return
	self.current_time += delta # convierte segundos reales a segundos de partida
	_check_events()
	_check_descontento(delta)


func get_date():
	var date_map = Time.get_date_dict_from_unix_time(
		self.start_date + (self.current_time * 86400)
	)
	return "%s, %s de %s de %s" % [
		dias[date_map["weekday"]],
		date_map["day"],
		meses[date_map["month"]- 1],
		date_map["year"],
		]
	
	
func _check_events():
	pass  #TO-DO

func _check_descontento(delta):
	descontento_up += delta*10
	if descontento_up >= 60:
		descontento_up = 0
		Player.descontento += 1
