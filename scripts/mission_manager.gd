extends Node

signal added_mission(mission: Mission)
signal warning_mission(mission: Mission)
signal clossed_mission(mission: Mission)

var scheduled_missions := {}
var active_missions  := {}
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
		scheduled_missions[mission.start] = mission
	TimeManager.run()
	set_process(true)
	file.close()

func deploy_mission(mission: Mission):
	scheduled_missions.erase(last_checked_second)
	mission.status = Mission.MISSION_STATUS.deployed
	active_missions[mission] = last_checked_second + 10
	added_mission.emit(mission)
	print("Launched mision: ", mission)
	
func warn_mission(mission: Mission):
	mission.status = Mission.MISSION_STATUS.warning
	warning_mission.emit(mission)
	print("Warned mision: ", mission)

func expire_mission(mission: Mission):
	active_missions.erase(mission)
	mission.status = Mission.MISSION_STATUS.expired
	clossed_mission.emit(mission)
	print("Expired mision: ", mission)

func resolve_mision(mission: Mission) -> void:
	active_missions.erase(mission)
	var rng = RandomNumberGenerator.new()
	var lucky = rng.randf_range(0, 1)
	if mission.get_probabity() < lucky: 
		mission.status = Mission.MISSION_STATUS.succeded
	else:
		mission.status = Mission.MISSION_STATUS.failed
	warning_mission.emit(mission)
	print("Resolved mision: ", mission)
	
func review_mision(mission: Mission) -> void:
	if mission.status == Mission.MISSION_STATUS.succeded:
		Player.successul_mission(mission)
	elif mission.status == Mission.MISSION_STATUS.failed:
		Player.failed_mission(mission)
	print("Reviewed mision: ", mission)
	clossed_mission.emit(mission)
