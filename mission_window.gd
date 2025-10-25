extends Panel

class_name MissionWindow

var mission: Mission
var assigned_agents = []

@onready var title = $TitleLabel
@onready var description = $DescriptionLabel
@onready var root_panel: Panel= $"."

func display_mission(new_mission: Mission):
	self.show()
	self.mission = new_mission
	self.title.text = new_mission.title
	self.description.text = new_mission.description
	self.root_panel.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)


func drag(_possition):
	return null

func can_drop_data(_position, data):
	print("agent droped")

	# "data" es lo que envía el nodo arrastrado (el agente)
	return data.has("agent_id")

func drop_data(_position, data):
	# Asigna el agente a este slot
	print("agent droped")
	self.assigned_agents.append(data)
	$AgentPortrait.texture = data.texture


func _on_button_closed_pressed() -> void:
	self.hide()


func _on_button_resolver_pressed() -> void:
	self.mission.resolve(self.assigned_agents)
