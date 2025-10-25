extends Node

var failed: bool
var game_time: float = 30
var mission_window

func start_day(map: Control, roster: Control, new_mission_window):	
	self.mission_window = new_mission_window
	var missions = []
	for mission in missions:
		map.add_child(mission)
	var agents = [] 
	for agent in agents:
		roster.add_child(agent)
				
	Global.descontento = 50
	Global.influencia= 0
	Global.iglesia = 15
	Global.nobleza = 15
	Global.rey = 15
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
