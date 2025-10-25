extends Node

signal influencia_changed(value)
signal descontento_changed(value)
signal nobleza_changed(value)
signal iglesia_changed(value)
signal rey_changed(value)

var influencia: float = 0.0:
	set(value):
		influencia = clamp(value, 0, 100)
		influencia_changed.emit(influencia)

var descontento: float = 50.0:
	set(value):
		descontento = clamp(value, 0, 100)
		descontento_changed.emit(descontento)

var nobleza: float = 20.0:
	set(value):
		nobleza = clamp(value, 0, 100)
		nobleza_changed.emit(nobleza)
		
var iglesia: float = 20.0:
	set(value):
		iglesia = clamp(value, 0, 100)
		iglesia_changed.emit(iglesia)

var rey: float = 80.0:
	set(value):
		rey = clamp(value, 0, 100)
		rey_changed.emit(rey)

func _ready():
	# Emitimos señales iniciales al arrancar el juego
	publish()

func publish():
	influencia_changed.emit(influencia)
	descontento_changed.emit(descontento)
	nobleza_changed.emit(nobleza)
	rey_changed.emit(rey)	
	iglesia_changed.emit(iglesia)	
