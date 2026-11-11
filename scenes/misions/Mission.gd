class_name Mission extends Resource

enum MISSION_STATUS {created, deployed, warning, expired, on_course, succeded, failed} 

@export var titulo: String
@export var mision: String
@export var rey: int
@export var clero: int
@export var nobleza: int
@export var descontento: int
@export var cura: int
@export var noble: int
@export var malechor: int
@export var x: int
@export var y: int
@export var start: int
@export var dificultad: int = 0
@export var resolve_time: int = 5
@export var slots: int = 4
@export var success_text : String
@export var failed_text : String

signal agents_changed

var resolve_at: float = 0.0
var agents : Array[Agent] = []
var status: MISSION_STATUS = MISSION_STATUS.created

func on_course():
	return self.status == MISSION_STATUS.on_course
	
func resolved():
	return self.status in [MISSION_STATUS.succeded, MISSION_STATUS.failed]
	
func success():
	return self.status == MISSION_STATUS.succeded
	
func get_probability()-> float:
	var n := agents.size()
	if n == 0:
		return 0.0
	var veterans := 0
	var has_affinity := false

	for agent in agents:
		if agent.veterano:
			veterans += 1

		if agent.faction == Factions.cura and cura > 0:
			has_affinity = true
		elif agent.faction == Factions.noble and noble > 0:
			has_affinity = true
		elif agent.faction == Factions.malechor and malechor > 0:
			has_affinity = true

	var probability := 30 + 15 * (n - 1)

	if has_affinity:
		probability += 25

	probability += 10 * veterans
	probability -= dificultad
	print("N: ", n)
	print("Veterans: ", veterans)
	print("Affinity: ", has_affinity)
	print("Difficulty: ", dificultad)
	print("Probability calculated: ", probability)
	
	return clampf(float(probability), 10.0, 90.0)

func set_agent(agent: Agent) -> void:
	if agent not in self.agents:
		self.agents.append(agent)
		agent.status = agent.AGENT_STATUS.ASSIGNED
		agents_changed.emit()

func clean_agent(agent: Agent) -> void:
	if agent in agents:
		agents.erase(agent)
		agent.unselect()
		agents_changed.emit()
	
func send_agents_home() -> void:
	print("Mission: Sending agents to home [%s]" % self.titulo)
	for agent in self.agents:
		agent.send_home(self.status == MISSION_STATUS.succeded)

func send_agents_mission():
	print("Mission: Sending agents to mission [%s]" % self.titulo)
	resolve_at = TimeManager.current_time + (resolve_time * TimeManager.SECONDS_PER_GAME_DAY)
	self.status = MISSION_STATUS.on_course
	print("Mission: Will resolve in %d game days" % resolve_time)

	
func resolve_mission():
	print("Mission: resolving mission[%s]" % self.titulo)
	print("Agents: ", agents.size())
	print("Difficulty: ", dificultad)
	var probability := get_probability()
	print("Probability before roll: ", probability)
	var rng = RandomNumberGenerator.new()
	var luck := rng.randf()
	if luck < probability/100.0:
		status = MISSION_STATUS.succeded
	else:
		status = MISSION_STATUS.failed

	print(
		"Mission: Resolved [%s] | Probability: %.1f%% | Roll: %.1f%% | Result: %s"
		% [titulo, probability, luck * 100.0, status]
	)
