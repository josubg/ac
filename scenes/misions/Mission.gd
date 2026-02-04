class_name Mission extends Resource

enum MISSION_STATUS {created, deployed, warning, succeded, failed, expired} 

@export var titulo: String
@export var mision: String
@export var rey: int
@export var clero: int
@export var nobleza: int
@export var descontento: int
@export var influencia: int
@export var cura: int
@export var noble: int
@export var malechor: int
@export var x: int
@export var y: int
@export var start: int
@export var duration_seconds: int = 10
@export var slots: int = 4
@export var success_text : String
@export var failed_text : String

var agents : Array[Agent] = []
var status: MISSION_STATUS = MISSION_STATUS.created


func resolved():
	return self.status in [MISSION_STATUS.succeded, MISSION_STATUS.failed]
	
func success():
	return self.status == MISSION_STATUS.succeded
	
func get_probabity():
	return len(agents)

func set_agent(agent: Agent) -> void:
	if agent not in self.agents:
		self.agents.append(agent)
		agent.status = agent.AGENT_STATUS.ASSIGNED

func clean_agent(agent: Agent) -> void:
	self.agents.erase(agent)
	agent.unselect()
	
func send_agents_home() -> void:
	for agent in self.agents:
		agent.send_home()
