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
var strike_1 = 40
var strike_2 = 20
var strike_3 = 10

var rey: int : 
	set(value):
		rey = clamp(int(value), -1, 101)
		rey_updated.emit(rey)
		check_factions()

var nobleza: int : 
	set(value):
		nobleza = clamp(int(value), -1, 101)
		nobleza_updated.emit(nobleza)
		check_factions()

var clero: int : 
	set(value):
		clero = clamp(int(value), -1, 101)
		clero_updated.emit(clero)
		check_factions()

var descontento: int :
	set(value):
		descontento = clamp(value, -1, 101)
		descontentoy_updated.emit(descontento)
		check_factions()

func start():
	self.rey = 50
	self.nobleza = 50
	self.clero = 50
	self.descontento = 50
	self.started = true
	
func successul_mission(mission: Mission):
	print("Player: Succesfull mission: ", mission)
	clero += mission.clero * bono
	rey += mission.rey * bono
	nobleza += mission.nobleza * bono
	descontento -= mission.descontento * bono
	
func failed_mission(mission):
	print("Player: Unsuccesfull mission: ", mission)
	clero -= mission.clero * penalizacion
	rey -= mission.rey * penalizacion
	nobleza -= mission.nobleza * penalizacion
	descontento += mission.descontento * penalizacion

func check_factions():
	if started:
		if rey == 0 or clero == 0 or nobleza == 0 or descontento > 99:
			MissionManager.end()
			GameManager.go_to_gameover()
			started = false
		else:
			if rey < strike_1 and rey_strike_1:
				emit_signal("rey_strike",1)
				rey_strike_1 = false
			elif rey < strike_2 and rey_strike_2:
				emit_signal("rey_strike",2)
				rey_strike_2 = false
			elif rey < strike_3 and rey_strike_3:
				emit_signal("rey_strike",3)
				rey_strike_3 = false	

			if clero < strike_1 and iglesia_strike_1:
				emit_signal("iglesia_strike",1)
				iglesia_strike_1 = false
			elif clero < strike_2 and iglesia_strike_2:
				emit_signal("iglesia_strike",2)
				iglesia_strike_2 = false
			elif clero < strike_3 and iglesia_strike_3:
				emit_signal("iglesia_strike",3)
				iglesia_strike_1 = false	

			if nobleza < strike_1 and noble_strike_1:
				emit_signal("noble_strike",1)
				noble_strike_1 = false
			elif nobleza < strike_2 and noble_strike_2:
				emit_signal("noble_strike",2)
				noble_strike_2 = false
			elif nobleza < strike_3 and noble_strike_3:
				emit_signal("noble_strike",3)
				noble_strike_3 = false
