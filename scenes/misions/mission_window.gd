class_name MissionWindow extends Control 

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var agent_roast: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/AgentRoast


const AGENT_SLOT = preload("res://scenes/agents/AgentSlot.tscn")
var mission : Mission

func _ready() -> void:
	self.hide()

func show_mission(new_mission: Mission) -> void:
	TimeManager.pause()
	print("show mission: ", mission)
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
	self.show()


func _on_send_pressed() -> void:
	MissionManager.resolve_mision(self.mission)
	self.mission = null
	TimeManager.resume()
	self.hide()

func _on_close_mission_button_pressed() -> void:
	TimeManager.resume()
	self.hide()
