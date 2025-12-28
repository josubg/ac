extends Node
class_name Player

signal death_signal(value)

var rey: int = 50
var nobleza: int = 75
var clero: int = 25
var descontento: int = 0

func mod_rey(value : int):
	rey += value
	rey = clamp(rey, 0, 100)

func mod_nobleza(value : int):
	nobleza += value
	nobleza = clamp(nobleza, 0, 100)

func mod_clero(value : int):
	clero += value
	clero = clamp(clero, 0, 100)

func mod_descontento(value : int):
	descontento += value
	descontento = clamp(descontento, 0, 100)
	if descontento <= 0:
		emit_signal("death_signal","descontento")
		
		
