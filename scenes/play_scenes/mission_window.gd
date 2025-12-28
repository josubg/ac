extends Control

@onready var title_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel

func show_mission(mission: MissionData) -> void:
	title_label.text = mission.titulo
	description_label.text = mission.mision

func close():
	hide()
