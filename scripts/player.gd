extends Node

signal rey_updated(value)
signal clero_updated(value)
signal nobleza_updated(value)
signal descontentoy_updated(value)

signal rey_strike(n : int)
signal noble_strike(n : int)
signal iglesia_strike(n : int)

var started = false

var rey_strike_1 = true
var rey_strike_2 = true
var rey_strike_3 = true
var noble_strike_1 = true
var noble_strike_2 = true
var noble_strike_3 = true
var iglesia_strike_1 = true
var iglesia_strike_2 = true
var iglesia_strike_3 = true
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
	self.rey = 50
	self.nobleza = 50
	self.clero = 50
	self.descontento = 10
	self.started = true
	
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
		if rey < 40 and rey_strike_1:
			emit_signal("rey_strike",1)
			rey_strike_1 = false
		elif rey < 25 and rey_strike_2:
			emit_signal("rey_strike",2)
			rey_strike_2 = false
		if rey < 10 and rey_strike_3:
			emit_signal("rey_strike",3)
			rey_strike_3 = false	
		if rey == 0:
			GameManager.go_to_gameover()
			print("GAME OVER REY")
		elif rey > 75:
			pass
			#Activate extra agent
		if clero < 40 and iglesia_strike_1:
			emit_signal("iglesia_strike",1)
			iglesia_strike_1 = false
		elif clero < 25 and iglesia_strike_2:
			emit_signal("iglesia_strike",2)
			iglesia_strike_2 = false
		if clero < 10 and iglesia_strike_3:
			emit_signal("iglesia_strike",3)
			iglesia_strike_1 = false	
		if clero == 0:
			GameManager.go_to_gameover()
			print("GAME OVER CLERO")
		elif clero > 75:
			pass
			#Activate extra agent
		if nobleza < 40 and noble_strike_1:
			emit_signal("noble_strike",1)
			noble_strike_1 = false
		elif nobleza < 25 and noble_strike_2:
			emit_signal("noble_strike",2)
			noble_strike_2 = false
		elif nobleza < 10 and noble_strike_3:
			emit_signal("noble_strike",3)
			noble_strike_3 = false
		if nobleza == 0:
			GameManager.go_to_gameover()
			print("GAME OVER NOBLE")
		elif nobleza > 75:
			pass
			#Activate extra agent
		if descontento >  99:
			GameManager.go_to_gameover()
			print("GAME OVER DESCONTENTO")
		elif descontento < 1:
			pass
			#Activate extra agent
