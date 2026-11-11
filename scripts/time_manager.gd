extends Node

const SECONDS_PER_GAME_DAY: float = 10.0

@onready var current_time : float = 0.0
var paused: bool = false
var start_date = -10413788339
var days_since_discontent: int = 0
# Quién ha pedido la pausa (ventanas, mensaje de la monja...). El tiempo solo
# corre cuando no queda ninguna, así cerrar una ventana no reanuda con otra abierta.
var _pause_sources: Dictionary = {}


var dias = [ "DAY_SUNDAY", "DAY_MONDAY", "DAY_TUESDAY", "DAY_WEDNESDAY", "DAY_THURSDAY", "DAY_FRIDAY", "DAY_SATURDAY"]
var meses =["MONTH_JANUARY", "MONTH_FEBRUARY", "MONTH_MARCH", "MONTH_APRIL", "MONTH_MAY", "MONTH_JUNE", "MONTH_JULY", "MONTH_AUGUST", "MONTH_SEPTEMBER",
 "MONTH_OCTOBER", "MONTH_NOVEMBER", "MONTH_DECEMBER"]
var timers : Array[Timer] = []

var last_day: int = -1

func run():
	self.set_process(true)
	self.current_time = 0
	self.last_day = -1
	self.days_since_discontent = 0
	_pause_sources.clear()
	_apply_pause()
	
	
func  end():
	self.set_process(false)
	self.current_time = 0
	for timer in timers:
		timer.stop()
	self.timers.clear()
	_pause_sources.clear()
	_apply_pause()

func pause(source: Variant = &"global") -> void:
	_pause_sources[source] = true
	_apply_pause()

func resume(source: Variant = &"global") -> void:
	_pause_sources.erase(source)
	_apply_pause()

func _apply_pause() -> void:
	self.paused = not _pause_sources.is_empty()
	for timer in self.timers:
		timer.paused = self.paused

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
	
	return tr("DATE_FORMAT") % [
		tr(dias[date_map["weekday"]]),
		date_map["day"],
		tr(meses[date_map["month"]- 1]),
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
