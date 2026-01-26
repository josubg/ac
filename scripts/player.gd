extends Node

signal rey_updated(value)
signal clero_updated(value)
signal nobleza_updated(value)
signal descontentoy_updated(value)


var rey = 50: 
	set(value):
		rey = clamp(value, 0, 100)
		rey_updated.emit(rey)

var nobleza: int = 75: 
	set(value):
		nobleza = clamp(value, 0, 100)
		nobleza_updated.emit(nobleza)

var clero: int = 25: 
	set(value):
		clero = clamp(value, 0, 100)
		clero_updated.emit(clero)

var descontento: int = 0: 
	set(value):
		descontento = clamp(value, 0, 100)
		descontentoy_updated.emit(descontento)

func successul_mission(mission):
	print("Succesfull mission: ", mission)
	
		
func failed_mission(mission):
	print("Unsuccesfull mission: ", mission)
