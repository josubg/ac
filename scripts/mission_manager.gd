extends Node

signal added_mission(mission: Mission)
signal warning_mission(mission: Mission)
signal clossed_mission(mission: Mission)

var scheduled_missions = {}
var active_missions  = {}
var on_course_missions = []
var last_checked_second = -1

func _process(_delta: float) -> void:
	var seconds = int(floor(TimeManager.current_time))
	if last_checked_second >= seconds:
		return
	last_checked_second = seconds
	print(seconds)
	if scheduled_missions.has(seconds):
		deploy_mission(scheduled_missions[seconds])
	for mission in active_missions:
		if active_missions[mission] < seconds + 5:
			warn_mission(mission)
		if active_missions[mission] < seconds:
			expire_mission(mission)
	for mission in on_course_missions:
		if mission.resolved():
			resolve_mision(mission)
			
	 
func load_missions(path: String) -> void:
	scheduled_missions.clear()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el CSV: " + path)
		return
	 # Saltar cabecera
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 13:
			if row.size()> 1:
				push_warning("Discarded row", row)
			continue
		var mission := Mission.new()
		#Titulo,Mision,Rey,clero,Nobleza,Descontento,Influencia,cura,noble,malechor,x,y,start
		mission.titulo = row[0]
		mission.mision = row[1]
		mission.rey = int(row[2])
		mission.clero = int(row[3])
		mission.nobleza = int(row[4])
		mission.descontento = int(row[5])
		mission.influencia = int(row[6])
		mission.cura = int(row[7])
		mission.noble = int(row[8])
		mission.malechor = int(row[9])
		mission.x = int(row[10])
		mission.y = int(row[11])
		mission.start = int(row[12])
		if row.size() >= 15:
			print("EXITO TEXT: "+row[13])
			mission.success_text = row[13]
			mission.failed_text = row[14]
		else:
			mission.success_text = " Excelencia, tenemos controlada la situación y adjuntamos informes sobre lo sucedido."
			mission.failed_text = ""
		scheduled_missions[mission.start] = mission
	TimeManager.run()
	set_process(true)
	file.close()
	
func get_test_mission() -> Mission:
	var mission := Mission.new()
	mission.titulo = "MISION DE PRUEBA"
	mission.mision = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
	mission.rey = 10
	mission.clero = 10
	mission.nobleza = 10
	mission.descontento = 10
	mission.influencia = 10
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
	scheduled_missions.erase(last_checked_second)
	mission.status = Mission.MISSION_STATUS.deployed
	active_missions[mission] = last_checked_second + 10
	added_mission.emit(mission)
	print("Mission Manager: Launched mision: ", mission)
	
func warn_mission(mission: Mission):
	mission.status = Mission.MISSION_STATUS.warning
	warning_mission.emit(mission)
	print("Mission Manager: Warned mision: ", mission)

func expire_mission(mission: Mission):
	active_missions.erase(mission)
	mission.status = Mission.MISSION_STATUS.expired
	clossed_mission.emit(mission)
	print("Mission Manager: Expired mision: ", mission)
	
func send_agents(mission: Mission):
	active_missions.erase(mission)
	on_course_missions.append(mission)
	mission.send_agents_mission()
	warning_mission.emit(mission)
	print("Mission Manager: Agents sent: ", mission)
	
func resolve_mision(mission: Mission) -> void:
	warning_mission.emit(mission)
	on_course_missions.erase(mission)
	print("Mission Manager: Mission Acomplished: ", mission)
	
func review_mision(mission: Mission) -> void:
	if mission.success():
		Player.successul_mission(mission)
	else:
		Player.failed_mission(mission)
	mission.send_agents_home()
	clossed_mission.emit(mission)
	print("Mission Manager: Reviewed mision: ", mission)
