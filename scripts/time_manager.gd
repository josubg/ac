extends Node

@onready var current_time : float = 0.0
var descontento_up : float = 0
var paused: bool = false
var events: Array = []
var start_date = -10413788339
var descontento_delta = 600

var dias = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo",]
var meses =["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre",
 "Octubre", "Noviembre", "Diciembre"]
var timers : Array[Timer] = []
var timers_s : Array[Timer] = []

func run():
	self.set_process(true)
	self.current_time = 0
	self.resume()
	
func  end():
	self.set_process(false)
	self.current_time = 0
	for timer in timers:
		timer.stop()
	for timer in timers_s:
		timer.stop()
	self.timers.clear()

func pause():
	self.paused = true
	for timer in self.timers:
		timer.paused = true

func resume():
	self.paused = false
	for timer in self.timers:
		timer.paused = false
	for timer in self.timers_s:
		timer.paused = false
		
func get_timer(seconds) -> SceneTreeTimer:
	var timer = get_tree().create_timer(seconds)
	self.timers_s.append(timer)
	return timer

func add_timer(timer: Timer):
	self.timers.append(timer)

func remove_timer(timer: Timer):
	self.timers.erase(timer)

func _process(delta):
	if not self.paused:
		self.current_time += delta # convierte segundos reales a segundos de partida
		_check_descontento(delta)

func get_date():
	var date_map = Time.get_date_dict_from_unix_time(
		self.start_date + (self.current_time * 86400) / 3
	)
	return "%s, %s de %s de %s" % [
		dias[date_map["weekday"]],
		date_map["day"],
		meses[date_map["month"]- 1],
		date_map["year"],
	]

func _check_descontento(delta):
	descontento_up += delta 
	if descontento_up >= self.descontento_delta:
		descontento_up -= self.descontento_delta
		Player.descontento += 1
