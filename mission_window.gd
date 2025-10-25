extends Panel

class_name MissionWindow


@export var unselected_portrait: Texture2D

@onready var title = $TitleLabel
@onready var description = $DescriptionLabel
@onready var portraits = [$SlotContainer/AgentPortrait, $SlotContainer/AgentPortrait2]
@onready var drop_panel = $SlotContainer

var mission: Mission
var assigned_agents = [null,null]

func _ready() -> void:
	self.hide()
	for portrait: TextureButton in self.portraits:
		portrait.texture_disabled = self.unselected_portrait
		portrait.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)
	self.drop_panel.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)
	

func display_mission(new_mission: Mission):
	
	self.mission = new_mission
	self.title.text = new_mission.title
	self.description.text = new_mission.description
	self.show()


func drag(_possition):
	return null

func can_drop_data(_position, data):
	# "data" es lo que envía el nodo arrastrado (el agente)
	return data is Agent

func drop_data(_position, data: Agent):
	# Asigna el agente a este slot
	print("agent droped")
	for index in self.portraits.size():
		if self.assigned_agents[index] == null:
			set_agent(data, self.portraits[index], index)
			print("Asignado: ", index)
			break
		
	
func _on_button_closed_pressed() -> void:
	self.hide()

func _on_button_resolver_pressed() -> void:
	var valid_agents = []
	for agent in self.assigned_agents:
		if agent != null:
			valid_agents.append(agent)
	self.mission.resolve(valid_agents)
	self.mission = null
	for index in self.portraits.size():
		self.unset_agent(index)
	self.hide()

func _on_agent_portrait_pressed() -> void:
	unset_agent(0)

func _on_agent_portrait2_pressed() -> void:
	unset_agent(1)

func set_agent(agent:Agent, portrait: TextureButton, index: int):
	agent.assigned = true
	portrait.texture_normal = agent.selected
	portrait.disabled = false
	self.assigned_agents[index] = agent
	
func unset_agent(index: int):
	if self.portraits[index] != null:
		self.portraits[index].disabled = true
	if self.assigned_agents[index] != null:
		self.assigned_agents[index].assigned = false
		self.assigned_agents[index] = null
		
	
	
