extends Control

@onready var title_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var agent_roast = $Panel/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/AgentRoast

const AGENT_SLOT = preload("res://scenes/agents/AgentSlot.tscn")
var mission : Mission

func show_mission(new_mission: Mission) -> void:
	if mission != new_mission:
		mission = new_mission
		title_label.text = mission.titulo
		description_label.text = mission.mision
		for x in mission.slots:
			print("")
			var agent_slot = AGENT_SLOT.instantiate()
			agent_slot.mission = mission
			agent_roast.add_child(agent_slot)

func close():
	hide()
