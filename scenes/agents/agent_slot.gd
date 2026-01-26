class_name AgentSelector extends PanelContainer

@onready var portrait: TextureRect = $Portrait
@export var void_texture: Texture2D 

var mission : Mission
var agent: Agent

func _ready() -> void:
	self.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)

func drag(_possition):
	var old_agent = self.agent
	var drag_portrait = self.agent.generate_drag_portrait()
	set_drag_preview(drag_portrait)
	clean_agent()
	return old_agent

func can_drop_data(_position, data):
	return data is Agent

func drop_data(_position, data: Agent):
	# Asigna el agente a este slot
	if self.agent:
		clean_agent()
	set_agent(data)

func set_agent(new_agent: Agent):
	self.agent = new_agent
	self.portrait.texture = agent.portrait.texture
	MissionManager.set_agent(agent, mission)
	
func clean_agent():
	self.agent = null
	self.portrait.texture = self.void_texture
	MissionManager.clean_agent(agent, mission)
