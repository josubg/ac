extends Node

signal rey_updated(value)
signal clero_updated(value)
signal nobleza_updated(value)
signal descontentoy_updated(value)

var started = false

var penalizacion = 10
var bono = 5

var rey: int : 
	set(value):
		rey = clamp(value, 0, 100)
		rey_updated.emit(rey)
		check_factions()

var nobleza: int : 
	set(value):
		nobleza = clamp(value, 0, 100)
		nobleza_updated.emit(nobleza)
		check_factions()

var clero: int : 
	set(value):
		clero = clamp(value, 0, 100)
		clero_updated.emit(clero)
		check_factions()

var descontento: int :
	set(value):
		descontento = clamp(value, 0, 100)
		descontentoy_updated.emit(descontento)
		check_factions()

func start():
	self.started = true
	self.rey = 50
	self.nobleza = 50
	self.clero = 50
	self.descontento = 10
	
func successul_mission(mission: Mission):
	print("Succesfull mission: ", mission)
	clero += mission.clero * bono
	rey += mission.rey * bono
	nobleza += mission.nobleza * bono
	descontento -= mission.descontento * bono
	
func failed_mission(mission):
	print("Unsuccesfull mission: ", mission)
	clero -= mission.clero * penalizacion
	rey -= mission.rey * penalizacion
	nobleza -= mission.nobleza * penalizacion
	descontento += mission.descontento * penalizacion

func check_factions():
	if started:
		if rey < 0:
			GameManager.go_to_gameover()
		elif rey > 75:
			pass
			#Activate extra agent
		if clero < 0:
			GameManager.go_to_gameover()
		elif nobleza > 75:
			pass
			#Activate extra agent
		if nobleza < 0:
			GameManager.go_to_gameover()
		elif nobleza > 75:
			pass
			#Activate extra agent
		if descontento >  99:
			GameManager.go_to_gameover()
		elif descontento < 1:
			pass
			#Activate extra agent
