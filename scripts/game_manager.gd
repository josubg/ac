extends Node

var debrief_panel: DebriefPanel

func start_day():
	var missions = [
	
		
	]
	for mission in missions:
		$Map.add_child(mission)
	
func show_mission(mision: Mission):
	debrief_panel.show_mission(mision)

func clear_mission():
	debrief_panel.clear_mission()
