class_name MissionWindow extends Control 

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var agent_roast: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/AgentRoast
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var send_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Send


const AGENT_SLOT = preload("res://scenes/agents/AgentSlot.tscn")
var mission : Mission

func _ready() -> void:
	self.hide()

func show_mission(new_mission: Mission) -> void:
	TimeManager.pause()
	audio_stream_player.play()

	print("Mission window: show mission [%s]" % new_mission.titulo)

	if mission != new_mission:
		if mission and mission.agents_changed.is_connected(update_send_button):
			mission.agents_changed.disconnect(update_send_button)
		
		for agent_slot in agent_roast.get_children():
			agent_roast.remove_child(agent_slot)
			agent_slot.queue_free()

		mission = new_mission
		mission.agents_changed.connect(update_send_button)
		title_label.text = mission.titulo
		description_label.text = mission.mision

		for x in mission.slots:
			var agent_slot = AGENT_SLOT.instantiate()
			agent_slot.mission = mission
			agent_roast.add_child(agent_slot)

	send_button.disabled = mission.agents.is_empty()
	self.show()

func _on_send_pressed() -> void:
	MissionManager.send_agents(self.mission)
	self.mission = null
	TimeManager.resume()
	self.hide()

func _on_close_mission_button_pressed() -> void:
	TimeManager.resume()
	self.hide()

func update_send_button() -> void:
	send_button.disabled = mission.agents.is_empty()
