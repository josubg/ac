extends Node

var failed: bool
var game_time: float = 300
var mission_window


func load_missions():
	var path ="res://data/missiones.txt"
	if FileAccess.file_exists(path):
		print("File found!")
	else:
		print("File not found!")
	var file = FileAccess.open(path , FileAccess.READ)
	print(file.get_line())
	print(file.get_line())
	var rng = RandomNumberGenerator.new()
	var missions = []
	var mission_scene =  preload("res://mission.tscn")
	while not  file.eof_reached():
		var missions_params = file.get_csv_line()
		if len(missions_params) < 11:
			print("line skiped: ", missions_params)
		else:			
			var m = mission_scene.instantiate()
			m.title= missions_params[0]
			m.description = missions_params[1]
			m.rey = int(missions_params[2])
			m.iglesia = int(missions_params[3])
			m.nobleza = int(missions_params[4])
			m.descontento = int(missions_params[5])
			m.influencia = int(missions_params[6])
			m.valid_cura = int(missions_params[7])
			m.valid_noble = int(missions_params[8])
			m.valid_malechor = int(missions_params[9])
			m.position = Vector2(
				int(missions_params[10]) + rng.randf_range(-50, 50), 
				int(missions_params[11]) + rng.randf_range(-50, 50))
			m.start = 12 * (len(missions)) + rng.randf_range(-5, 5)
			m.life = 30 + rng.randf_range(0, 15)
			missions.append(m)
	return missions

func load_agents():
	return []

func start_day(map: Control, roster: Control, new_mission_window):	
	self.mission_window = new_mission_window
	var missions = load_missions()
	print("created missions", len(missions))
	for mission in missions:
		map.add_child(mission)
	var agents = load_agents()
	for agent in agents:
		roster.add_child(agent)
	Global.descontento = 50
	Global.influencia= 50
	Global.iglesia = 50
	Global.nobleza = 50
	Global.rey = 50
	Global.descontento_changed.connect(check_victory)
	Global.iglesia_changed.connect(check_victory)
	Global.influencia_changed.connect(check_victory)
	Global.nobleza_changed.connect(check_victory)
	Global.rey_changed.connect(check_victory)
	
	Global.publish()
	self.failed = false
	await get_tree().create_timer(game_time).timeout
	self.end_day()
	
	
	
func show_mission(mision: Mission):
	self.mission_window.display_mission(mision)


func start():
	get_tree().change_scene_to_file("res://main_scene.tscn")


func check_victory(value):
	if Global.descontento > 99:
		defeat()
	if Global.nobleza < 1:
		defeat()
	if Global.rey < 1:
		defeat()
	if Global.iglesia < 1:
		defeat()
	
func end_day():
	if not self.failed:
		victory()
	else:
		defeat()

func victory():
	get_tree().change_scene_to_file("res://victory.tscn")

func defeat():
	get_tree().change_scene_to_file("res://defeat.tscn")
