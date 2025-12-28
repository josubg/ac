extends Node

@onready var time_manager: Node = $TimeManager
@onready var player: Player = $Player
@onready var mission_manager: Node = $MissionManager
@onready var mission_window: Control = $CanvasLayerMission/PanelMission/MissionWindow
@onready var panel_mission: Panel = $CanvasLayerMission/PanelMission

@onready var time_label: Label = $CanvasLayer/VBoxContainer/HBoxContainer/ColorRect/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer2/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer3/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayer/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/DescontentoBar
@onready var map_ui: Control = $CanvasLayer/MapUI


@export var mission_button_scene: PackedScene = preload("res://scenes/play_scenes/MissionButton.tscn")

var last_checked_second := -1

func _ready() -> void:
	time_manager.connect("descontento_sube",Callable(self, "_on_descontento_sube"))
	mission_manager.load_missions("res://resources/data/missions.txt")
	print("Misions:"+str(mission_manager.scheduled_missions))

func _process(_delta):
	var minutes = int(time_manager.current_time)
	var seconds = int((time_manager.current_time - minutes) * 60)
	#Comprobamos que no seguimos en el mismos egundo
	if seconds == last_checked_second:
		return
	last_checked_second = seconds
	#comprobamos misión
	var mission: MissionData = mission_manager.check_for_mission(seconds)
	if mission != null:
		launch_mission(mission)
		
	time_label.text = "%02d:%02d" % [minutes, seconds]
	rey_bar.value = player.rey
	_update_color(rey_bar, player.rey,false)
	nobleza_bar.value = player.nobleza
	_update_color(nobleza_bar, player.nobleza,false)
	clero_bar.value = player.clero
	_update_color(clero_bar, player.clero,false)
	descontento_bar.value = player.descontento
	_update_color(descontento_bar, player.descontento,true)

func launch_mission(mission: MissionData) -> void:
	#anyadir boton de mision
	var button: MissionButton = mission_button_scene.instantiate()
	map_ui.add_child(button)
	button.position = Vector2(mission.x, mission.y)
	print("Mision:"+str(button.position))
	button.setup(mission)
	button.mission_pressed.connect(_on_mission_pressed)
	
	
func _on_descontento_sube():
	player.mod_descontento(1)

func _update_color(faction : ProgressBar, value: float, inverse: bool) -> void:
	var color_ratio = value / 100.0
	var color = Color.RED.lerp(Color.GREEN, color_ratio)
	if inverse:
		color = Color.GREEN.lerp(Color.RED, color_ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	faction.add_theme_stylebox_override("background", style)
	
func _on_mission_pressed(mission: MissionData) -> void:
	#actualizar ventana
	print("Pressed")
	mission_window.show_mission(mission)
	panel_mission.show()
