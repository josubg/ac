extends Node

signal added_mission(mission: Mission)
signal warning_mission(mission: Mission)
signal clossed_mission(mission: Mission)

var scheduled_missions: Dictionary = {}
var active_missions  = {}
var on_course_missions = []
var review_missions = []
var last_checked_second = -1
var last_checked_day = -1

var mission_count :int: 
	get():
		return len(scheduled_missions) + len(active_missions) + len(on_course_missions) + len(review_missions)

func _ready() -> void:
	set_process(false)

func _process(_delta: float) -> void:
	var seconds = int(floor(TimeManager.current_time))
	
	if last_checked_second >= seconds:
		return
	
	last_checked_second = seconds
	
	# Día de juego transcurrido.
	var game_day = int(floor(TimeManager.current_time / TimeManager.SECONDS_PER_GAME_DAY))
	# Comprobar aparición de misiones.
	if last_checked_day != game_day:
		last_checked_day = game_day

		if scheduled_missions.has(game_day):
			var missions_today: Array = scheduled_missions[game_day]
			scheduled_missions.erase(game_day)

			for mission in missions_today:
				deploy_mission(mission)
			
	for mission in active_missions.keys():
		var deadline = active_missions[mission]

		if deadline <= seconds + 5 and mission.status != Mission.MISSION_STATUS.warning:
			warn_mission(mission)

		if deadline <= seconds:
			expire_mission(mission)

	for mission in on_course_missions.duplicate():
		if mission.on_course() and TimeManager.current_time >= mission.resolve_at:
			mission.resolve_mission()

		if mission.resolved():
			resolve_mision(mission)
	 
func load_missions(path: String) -> void:
	set_process(false)
	
	last_checked_second = -1
	last_checked_day = -1
	
	scheduled_missions.clear()
	active_missions.clear()
	on_course_missions.clear()
	review_missions.clear()
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el CSV: " + path)
		return
		
	# Saltar cabecera
	file.get_csv_line()
	
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 16:
			continue
			
		var mission := Mission.new()
		mission.titulo = row[0]
		mission.mision = row[1]
		
		mission.rey = int(row[2])
		mission.clero = int(row[3])
		mission.nobleza = int(row[4])
		mission.descontento = int(row[5])
		
		mission.cura = int(row[6])
		mission.noble = int(row[7])
		mission.malechor = int(row[8])
		
		mission.x = int(row[9])
		mission.y = int(row[10])
		
		mission.start = int(row[11])
		mission.resolve_time = int(row[12])
		mission.dificultad = int(row[13])
		
		mission.success_text = row[14]
		mission.failed_text = row[15]
		# Guardar la misión en el día correspondiente
		if not scheduled_missions.has(mission.start):
			scheduled_missions[mission.start] = []
			
		scheduled_missions[mission.start].append(mission)
	
	file.close()
	TimeManager.run()
	set_process(true)
	
	
	
func get_test_mission() -> Mission:
	var mission := Mission.new()
	mission.titulo = "MISION DE PRUEBA"
	mission.mision = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
	mission.rey = 10
	mission.clero = 10
	mission.nobleza = 10
	mission.descontento = 10
	mission.cura = 1
	mission.noble = 1
	mission.malechor = 0
	mission.x = 500
	mission.y = 500
	mission.start = 0
	mission.success_text = "Todo ha salido a pedir de Millhouse"
	mission.failed_text = "Ay caramba"
	scheduled_missions[mission.start] = mission
	return mission

func deploy_mission(mission: Mission):
	scheduled_missions.erase(mission.start)
	mission.status = Mission.MISSION_STATUS.deployed
	active_missions[mission] = int(floor(TimeManager.current_time)) + 15
	added_mission.emit(mission)
	print("Mission Manager: Launched mission: [%s] - Día [%s]" % [mission.titulo, mission.start])
	
func warn_mission(mission: Mission):
	mission.status = Mission.MISSION_STATUS.warning
	warning_mission.emit(mission)
	print("Mission Manager: Warned mision: [%s]" % mission.titulo)

func expire_mission(mission: Mission):
	active_missions.erase(mission)
	mission.status = Mission.MISSION_STATUS.expired
	Player.failed_mission(mission)
	clossed_mission.emit(mission)
	print("Mission Manager: Expired mision: [%s]" % mission.titulo)
	
func send_agents(mission: Mission):
	active_missions.erase(mission)
	on_course_missions.append(mission)
	mission.send_agents_mission()
	warning_mission.emit(mission)
	print("Mission Manager: Agents sent: [%s]" % mission.titulo)
	
func resolve_mision(mission: Mission) -> void:
	warning_mission.emit(mission)
	on_course_missions.erase(mission)
	review_missions.append(mission)
	print("Mission Manager: Mission Acomplished: [%s]" % mission.titulo)
	
func review_mision(mission: Mission) -> void:
	review_missions.erase(mission)
	if mission.success():
		Player.successul_mission(mission)
	else:
		Player.failed_mission(mission)
	mission.send_agents_home()
	clossed_mission.emit(mission)
	print("Mission Manager: Reviewed mision: [%s]" % mission.titulo)

func end():
	TimeManager.end()
	scheduled_missions.clear()
	active_missions.clear()
	on_course_missions.clear()
	review_missions.clear()
	set_process(false)
