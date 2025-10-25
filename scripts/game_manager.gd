extends Node

var mission_window: MissionWindow



func start_day(map: Control, roster: Control):
	get_tree().change_scene_to_file("res://main_scene.tscn")
	var missions = []
	for mission in missions:
		map.add_child(mission)
	var agents = [] 
	for agent in agents:
		roster.add_child(agent)
				
	Global.descontento_changed.connect(check_victory)
	Global.iglesia_changed.connect(check_victory)
	Global.influencia_changed.connect(check_victory)
	Global.nobleza_changed.connect(check_victory)
	Global.rey_changed.connect(check_victory)
	
	
func show_mission(mision: Mission):
	self.mission_window.display_mission(mision)

func clear_mission():
	pass
	#debrief_panel.clear_mission()

func start():
	self.mission_window.hide()
	Global.publish()
	

func check_victory(value):
	if Global.descontento > 99:
		pass
	if Global.influencia < 1:
		pass
	if Global.nobleza < 1:
		pass
	if Global.rey < 1:
		pass
	if Global.iglesia < 1:
		pass
	
func victory():
	get_tree().change_scene_to_file("res://victory.tscn")

func defeat():
	get_tree().change_scene_to_file("res://defeat.tscn")
