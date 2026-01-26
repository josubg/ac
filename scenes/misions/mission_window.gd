extends Control

@onready var title_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label = $Panel/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var agent_roast = $Panel/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/AgentRoast
const AGENT_SLOT = preload("res://scenes/agents/AgentSlot.tscn")
var mission : Mission

func show_mission(new_mission: Mission) -> void:
	if mission != new_mission:
		for agent_slot in agent_roast.get_children():
			agent_roast.remove_child(agent_slot)
		mission = new_mission
		title_label.text = mission.titulo
		description_label.text = mission.mision
		for x in mission.slots:
			var agent_slot = AGENT_SLOT.instantiate()
			agent_slot.mission = mission
			agent_roast.add_child(agent_slot)


func _on_send_pressed() -> void:
	MissionManager.resolve_mision(self.mission)
	self.mission = null
	self.get_parent().hide()
