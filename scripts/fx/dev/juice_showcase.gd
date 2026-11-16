extends Node
## Escena de desarrollo: juega una partida en automático y dispara cada efecto
## de juice para revisarlos y capturarlos. No forma parte del juego.
##
##   Godot --path . res://scripts/fx/dev/juice_showcase.tscn
##   (añadir --write-movie docs/vfx/capture/juice.avi --fixed-fps 30 para grabar)
## Las capturas PNG se guardan en res://docs/vfx/ (solo desde el editor/desarrollo).

const OUT_DIR := "res://docs/vfx/"


func _ready() -> void:
	# GameManager cambia de escena al arrancar y liberaría esta: el guion vive
	# en un nodo aparte colgado de la raíz.
	var runner := Node.new()
	runner.name = "JuiceShowcaseRunner"
	runner.set_script(load("res://scripts/fx/dev/juice_showcase_runner.gd"))
	get_tree().root.add_child.call_deferred(runner)
