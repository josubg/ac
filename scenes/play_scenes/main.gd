extends Node

@onready var time_manager: Node = $TimeManager
@onready var player: Player = $Player

@onready var time_label: Label = $CanvasLayer/VBoxContainer/HBoxContainer/ColorRect/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer2/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer3/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayer/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/DescontentoBar

func _ready() -> void:
	time_manager.connect("descontento_sube",Callable(self, "_on_descontento_sube"))

func _process(_delta):
	var minutes = int(time_manager.current_time)
	var seconds = int((time_manager.current_time - minutes) * 60)
	time_label.text = "%02d:%02d" % [minutes, seconds]
	rey_bar.value = player.rey
	nobleza_bar.value = player.nobleza
	clero_bar.value = player.clero
	descontento_bar.value = player.descontento

func _on_descontento_sube():
	player.mod_descontento(1)
