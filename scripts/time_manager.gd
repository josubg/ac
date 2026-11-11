extends Node

const SECONDS_PER_GAME_DAY: float = 10.0

@onready var current_time : float = 0.0
var descontento_up : float = 0
var paused: bool = false
var events: Array = []
var start_date = -10413788339
var descontento_delta = 600
var days_since_discontent: int = 0


var dias = [ "Domingo", "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado"]
var meses =["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre",
 "Octubre", "Noviembre", "Diciembre"]
var timers : Array[Timer] = []
var timers_s : Array[Timer] = []

var last_day: int = -1

func run():
	self.set_process(true)
	self.current_time = 0
	self.last_day = -1
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
	var timer = get_tree().create_timer(seconds, false)
	self.timers_s.append(timer)
	return timer

func add_timer(timer: Timer):
	self.timers.append(timer)

func remove_timer(timer: Timer):
	self.timers.erase(timer)

func _process(delta):
	if not self.paused:
		self.current_time += delta # convierte segundos reales a segundos de partida
		_check_day_change()
		

func get_date():
	var date_map = get_date_map()
	
	return "%s, %s de %s de %s" % [
		dias[date_map["weekday"]],
		date_map["day"],
		meses[date_map["month"]- 1],
		date_map["year"],
	]

func _check_day_change():
	var date_map = get_date_map()
	if date_map["day"] != last_day:
		last_day = date_map["day"]
		days_since_discontent += 1
		if days_since_discontent >= 2:
			Player.descontento += 1
			days_since_discontent = 0
		Player.riqueza += BuildingManager.get_player_income_per_turn()
		BuildingManager.apply_player_building_influence()
		print("Riqueza: "+str(Player.riqueza))
		BuildingManager.get_player_income_breakdown()

func get_date_map() -> Dictionary:
	var elapsed_game_days = current_time / SECONDS_PER_GAME_DAY

	return Time.get_date_dict_from_unix_time(
		start_date + int(elapsed_game_days * 86400)
	)
