extends CanvasLayer

@onready var map = $MainContainer/MapPanel/Map
@onready var roster = $MainContainer/AgentPanel/AgentBar
@onready var mission_window = $MainContainer/MapPanel/MissionWindow


func _ready() -> void:
	GameManager.start_day(map, roster, mission_window)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
