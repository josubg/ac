extends Node

var scheduled_missions := {}

func check_for_mission(time: int) -> Mission:
	if scheduled_missions.has(time):
		var mission := Mission.new()
		mission = scheduled_missions[time]
		scheduled_missions.erase(time)
		return mission
	return null

	 
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
		#Titulo,Mision,Rey,Iglesia,Nobleza,Descontento,Influencia,cura,noble,malechor,x,y,start
		mission.titulo = row[0]
		mission.mision = row[1]
		mission.rey = int(row[2])
		mission.iglesia = int(row[3])
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
	file.close()
	
func set_agent(agent: Agent, mission: Mission) -> void:
	if agent not in mission.agents:
		mission.agents.append(agent)

func clean_agent(agent: Agent, mission: Mission) -> void:
	mission.agents.erase(agent)

func resolve_mision(mission: Mission) -> void:
	var rng = RandomNumberGenerator.new()
	var lucky = rng.randf_range(0, 1)
	if mission.get_thresshold() < lucky: 
		Player.successul_mission(mission)
	else:
		Player.failed_mission(mission)
