extends Node

signal rey_updated(value)
signal clero_updated(value)
signal nobleza_updated(value)
signal descontentoy_updated(value)

var  started = false

var rey = 50: 
	set(value):
		rey = clamp(value, 0, 100)
		rey_updated.emit(rey)
		check_factions()

var nobleza: int = 75: 
	set(value):
		nobleza = clamp(value, 0, 100)
		nobleza_updated.emit(nobleza)
		check_factions()

var clero: int = 25: 
	set(value):
		clero = clamp(value, 0, 100)
		clero_updated.emit(clero)
		check_factions()

var descontento: int = 0: 
	set(value):
		descontento = clamp(value, 0, 100)
		descontentoy_updated.emit(descontento)
		check_factions()

func successul_mission(mission: Mission):
	print("Succesfull mission: ", mission)
	clero += mission.clero
	rey += mission.rey
	nobleza += mission.nobleza
	descontento -= mission.descontento
	
func failed_mission(mission):
	print("Unsuccesfull mission: ", mission)
	clero -= mission.clero
	rey -= mission.rey
	nobleza -= mission.nobleza
	descontento += mission.descontento

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
