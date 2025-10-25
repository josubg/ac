extends Node

var mission_window: MissionWindow


func start_day():
	var missions = [
	]
	for mission in missions:
		$Map.add_child(mission)
	
func show_mission(mision: Mission):
	self.mission_window.display_mission(mision)

func clear_mission():
	pass
	#debrief_panel.clear_mission()

func start():
	self.mission_window.hide()
	Global.publish()
