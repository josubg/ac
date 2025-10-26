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

@export var valid_noble: int
@export var valid_cura: int
@export var valid_malechor: int



var exito: bool
var resuelta: bool
var fin: bool
var rng: RandomNumberGenerator

func _ready():
	print("Mission deployed", self.title, self.start, self.life)
	self.rng = RandomNumberGenerator.new()
	self.hide()
	var tree = get_tree() 
	await tree.create_timer(start).timeout
	deploy()
	await tree.create_timer(life).timeout
	if not self.resuelta:
		print("Timeout: ", self.title)
		finalize()
	
func deploy():
	print("Mission started", self.title)
	self.show()
	self.exito = false
	self.fin = false
	self.resuelta = false
	
func finalize():
	if not self.fin:
		self.fin = true
		if exito:
			print("Mission succesfull")
			Global.influencia += self.influencia
			Global.descontento += self.descontento 
			Global.nobleza += self.nobleza * 10
			Global.iglesia += self.iglesia * 10
			Global.rey += self.rey * 10
		else: 
			print("Mission failed")
			Global.influencia-= self.influencia
			Global.descontento -= self.descontento
			Global.nobleza -= self.nobleza * 10
			Global.iglesia -= self.iglesia * 10
			Global.rey -= self.rey * 10
		self.hide()

func _on_pressed() -> void:
	GameManager.show_mission(self)
	
func resolve(agents: Array) -> void:
	self.resuelta = true
	print("Agentes enviados:", self.title)
	self.hide()
	var tree = get_tree() 
	await tree.create_timer(10).timeout
	var deploy_agents: int = 0
	var good_assing: int  = 0
	for agent: Agent in agents:
		deploy_agents += 1
		if agent.cura:
			if self.valid_cura:
				good_assing += 1
		if agent.noble:
			if self.valid_noble > 0:
				good_assing += 1
		if agent.cura:
			if self.valid_cura > 0:
				good_assing += 1
	var limit = 0 
	if len(agents) >0:
		limit  = 50
	if len(agents) >1:
		limit = 75
	limit += 25 * good_assing
	print( "Probabilidad", limit)
	self.exito = rng.randf_range(0, 100) < limit
	if exito:
		print("Exito:", self.title)
	else :
		print("Fracaso:", self.title)
	for agente in agents:
		if agente != null:
			agente.assigned= false
	self.finalize()
