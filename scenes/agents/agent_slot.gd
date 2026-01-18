class_name AgentSelector extends PanelContainer

@onready var portrait: TextureRect = $Portrait

var mission : Mission
var agent: Agent

func _ready() -> void:
	self.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)

func drag(_possition):
	return null

func can_drop_data(_position, data):
	return data is Agent

func drop_data(_position, data: Agent):
	# Asigna el agente a este slot
	if agent:
		clean_agent()
	set_agent(data)

func set_agent(new_agent: Agent):
	agent = new_agent
	portrait.texture = agent.portrait.texture
	MissionManager.set_agent(agent, mission)
	
func clean_agent():
	MissionManager.clean_agent(agent, mission)
