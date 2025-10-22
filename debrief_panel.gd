extends Panel

class_name DebriefPanel

func show_mission(mision: Mission):
	$debrief.text = mision.debrief

func clear_mission():
	$debrief.text = "No Mission seleted yet"
