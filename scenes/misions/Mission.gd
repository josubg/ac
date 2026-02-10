class_name Mission extends Resource

enum MISSION_STATUS {created, deployed, warning, expired, on_course, succeded, failed} 

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
@export var resolve_time: int = 5
@export var slots: int = 4
@export var success_text : String
@export var failed_text : String

var timer: SceneTreeTimer
var agents : Array[Agent] = []
var status: MISSION_STATUS = MISSION_STATUS.created

var bono_agente: int = 30
var bono_faccion: int = 30
var bono_veterano: int = 10
var penalizacion: int = 10

func on_course():
	return self.status == MISSION_STATUS.on_course
	
func resolved():
	return self.status in [MISSION_STATUS.succeded, MISSION_STATUS.failed]
	
func success():
	return self.status == MISSION_STATUS.succeded
	
func get_probabity()-> float:
	var  prob = 0
	for agent in agents:
		prob += bono_agente
		if agent.faction == Factions.cura:
			prob += bono_faccion * self.cura
		if agent.faction == Factions.malechor:
			prob += bono_faccion * self.malechor
		if agent.faction == Factions.noble:
			prob += bono_faccion * self.noble
		if agent.veterano:
			prob += bono_veterano
	prob -= penalizacion * (len(agents) - 1)
	#return float(prob) / 100
	return 1

func set_agent(agent: Agent) -> void:
	if agent not in self.agents:
		self.agents.append(agent)
		agent.status = agent.AGENT_STATUS.ASSIGNED

func clean_agent(agent: Agent) -> void:
	self.agents.erase(agent)
	agent.unselect()
	
func send_agents_home() -> void:
	print("Mission: Sending agents to home [%s]" % self.titulo)
	for agent in self.agents:
		agent.send_home(self.status == MISSION_STATUS.succeded)

func send_agents_mission():
	print("Mission: Sending agents to mission [%s]" % self.titulo)
	timer = TimeManager.get_timer(resolve_time)
	self.status = MISSION_STATUS.on_course
	timer.timeout.connect(self.resolve_mission)

	
func resolve_mission():
	print("Mission: resolving mission[%s]" % self.titulo)
	var rng = RandomNumberGenerator.new()
	var luck = rng.randf_range(0, 1)
	var confidence = self.get_probabity()
	if luck > confidence: 
		self.status = MISSION_STATUS.failed
	else:
		self.status = MISSION_STATUS.succeded
	print("Mission: Resolved mision[%s]  %s > %s  %s" % [self.titulo, confidence, luck , self.status])
