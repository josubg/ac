extends Node

@onready var mission_window: Control = $CanvasLayerMission/PanelMission/MissionWindow
@onready var panel_mission: Panel = $CanvasLayerMission/PanelMission


@onready var time_label: Label = $CanvasLayerMission/VBoxContainer/HBoxContainer/ColorRect/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer2/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer3/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/DescontentoBar
@onready var buttons_layer: Control = $CanvasLayerMission/ButtonsLayer

@onready var active_missions: Dictionary[Mission, int] = {}
@onready var active_mission_buttons: Dictionary[Mission, MissionButton] = {}

@onready var mission_button_scene: PackedScene = load("res://scenes/misions/MissionButton.tscn")

var last_checked_second := -1

func _ready() -> void:
	Player.clero_updated.connect(update_clero)
	Player.nobleza_updated.connect(update_nobleza)
	Player.rey_updated.connect(update_rey)
	Player.descontentoy_updated.connect(update_descontento)
	MissionManager.load_missions("res://resources/data/missions.txt")
	print("Misions: "+str(MissionManager.scheduled_missions))

func _process(_delta):
	var minutes = int(TimeManager.current_time)
	var seconds = int((TimeManager.current_time - minutes) * 60)
	#Comprobamos que no seguimos en el mismos egundo
	if seconds == last_checked_second:
		return
	last_checked_second = seconds
	#comprobamos misión
	var mission: Mission = MissionManager.check_for_mission(seconds)
	if mission != null:
		launch_mission(mission, seconds)
	
	#comprobamos parpadeo mision
	for m in active_missions:
		if active_missions[m] < seconds+5:
			var button := active_mission_buttons[m]
			button.start_blinking()
	#comprobamos fin mision
	for m in active_missions:
		if active_missions[m] < seconds:
			active_missions.erase(m)
			var button := active_mission_buttons[m]
			button.queue_free()
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
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

func launch_mission(mission: Mission, seconds: int) -> void:
	#anyadir boton de mision
	var button: MissionButton = mission_button_scene.instantiate()
	buttons_layer.add_child(button)
	button.position = Vector2(mission.x, mission.y)
	print("Mision: " + str(button.position))
	button.setup(mission)
	button.mission_pressed.connect(_on_mission_pressed)
	active_mission_buttons[mission] = button
	active_missions[mission] = seconds + mission.duration_seconds

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
	#actualizar ventana
	panel_mission.show()
	mission_window.show_mission(mission)

func _on_close_mission_button_pressed() -> void:
	panel_mission.hide()
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			GameManager.go_to_menu()
