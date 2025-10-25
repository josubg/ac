extends TextureButton

class_name Mission
@export var start: float
@export var life: float

@export var title: String
@export var description: String

@export var influencia: int
@export var descontento: int
@export var nobleza: int
@export var iglesia: int
@export var rey: int

@export var debrief: String
var exito: bool
var fin: bool
var rng: RandomNumberGenerator

func _ready():
	self.rng = RandomNumberGenerator.new()
	self.hide()
	var tree = get_tree() 
	await tree.create_timer(start).timeout
	deploy()
	await tree.create_timer(life).timeout
	finalize()
	
	
func deploy():
	print("Mission started")
	self.show()
	self.exito = false
	self.fin = false
	
	
func finalize():
	if not self.fin:
		if exito:
			print("Mission succesfull")
			Global.influencia += self.influencia
			Global.descontento += self.descontento
			Global.nobleza += self.nobleza
			Global.iglesia += self.iglesia
			Global.rey += self.rey
		else: 
			print("Mission failed")
			Global.influencia-= self.influencia
			Global.descontento -= self.descontento
			Global.nobleza -= self.nobleza
			Global.iglesia -= self.iglesia
			Global.rey -= self.rey	
		self.hide()
		self.fin = true


func _on_pressed() -> void:
	GameManager.show_mission(self)
	
func resolve(agents: Array) -> void:
	var deploy_agents: int = 0
	var good_assing: int  = 0
	var bad_asing: int  = 0
	for agent: Agent in agents:
		deploy_agents += 1
		if agent.iglesia:
			if self.iglesia > 0:
				good_assing += 1
			if self.iglesia < 0:
				bad_asing += 1
		if agent.nobleza:
			if self.nobleza > 0:
				good_assing += 1
			if self.nobleza < 0:
				bad_asing += 1	 
		#if agent.rey:
			#if self.rey > 0:
				#good_assing += 1
			#if self.rey < 0:
				#bad_asing += 1	
	
	var limit: int = 100 / max(deploy_agents + good_assing - bad_asing + 1, 1)
	print( "Probabilidad", limit)
	self.exito = rng.randf_range(0, 100) > limit
	print("Exito: ", exito)
	for agente in agents:
		if agente != null:
			agente.assigned= false
	self.finalize()
