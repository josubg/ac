extends CanvasLayer


func _ready() -> void:
	GameManager.mission_window = $MainContainer/MapPanel/MissionWindow
	GameManager.start()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
