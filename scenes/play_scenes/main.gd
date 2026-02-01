extends Node

@onready var mission_window: Control = $CanvasLayerMission/MissionWindow

@onready var time_label: Label = $CanvasLayerMission/VBoxContainer/HBoxContainer/ColorRect/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer2/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer3/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/DescontentoBar
@onready var buttons_layer: Control = $CanvasLayerMission/VBoxContainer/ButtonsLayer

@onready var active_missions: Dictionary[Mission, int] = {}
@onready var active_mission_buttons: Dictionary[Mission, MissionButton] = {}

@onready var mission_button_scene: PackedScene = load("res://scenes/misions/MissionButton.tscn")

var buttons: Array[MissionButton]= []

func _ready() -> void:
	Player.clero_updated.connect(update_clero)
	Player.nobleza_updated.connect(update_nobleza)
	Player.rey_updated.connect(update_rey)
	Player.descontentoy_updated.connect(update_descontento)
	MissionManager.added_mission.connect(mission_added)
	MissionManager.warning_mission.connect(mission_updated)
	MissionManager.clossed_mission.connect(mission_removed)
	MissionManager.load_missions("res://resources/data/missions.txt")
	print("Misions: "+str(MissionManager.scheduled_missions))

func _process(_delta):
	var minutes = int(TimeManager.current_time)
	var seconds = int((TimeManager.current_time - minutes) * 60)
	
	time_label.text = "%02d:%02d" % [minutes, seconds]

func mission_added(mission: Mission) -> void:
	print("Mision: " + str(mission.titulo))
	var button: MissionButton = mission_button_scene.instantiate()
	buttons.append(button)
	buttons_layer.add_child(button)
	button.position = Vector2(mission.x, mission.y)
	button.mission = mission
	button.mission_pressed.connect(_on_mission_pressed)
	
func mission_updated(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			if mission.resolved():
				button.set_gold()
			else:
				button.start_blinking()

func mission_removed(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			buttons_layer.remove_child(button)
			buttons.erase(button)
			button.queue_free()

func update_rey(value):
	rey_bar.value = value
	_update_color(rey_bar, value,false)

func update_nobleza(value):
	nobleza_bar.value = value
	_update_color(nobleza_bar,value,false)

func update_clero(value):
	clero_bar.value = value
	_update_color(clero_bar, value,false)
	
func update_descontento(value):
	descontento_bar.value = value
	_update_color(descontento_bar,value,true)

func _update_color(faction : ProgressBar, value: float, inverse: bool) -> void:
	var color_ratio = value / 100.0
	var color = Color.RED.lerp(Color.GREEN, color_ratio)
	if inverse:
		color = Color.GREEN.lerp(Color.RED, color_ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	faction.add_theme_stylebox_override("background", style)
	
func _on_mission_pressed(mission: Mission) -> void:
	if mission.resolved():
		# TODO SHOW resolve dialog()
		pass
	else:
		mission_window.show_mission(mission)
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			GameManager.go_to_menu()
