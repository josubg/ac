extends Node

# Estados del juego (opcional, útil para lógica)
enum State { NONE, INTRO, MENU, PLAYING, GAMEOVER }
var state : State = State.NONE

# Rutas a escenas (ajusta según tu proyecto)
@export var intro_scene_path  : String = "res://scenes/Intro_Video.tscn"
@export var menu_scene_path   : String = "res://scenes/menu_inicio.tscn"
@export var game_scene_path   : String = "res://scenes/play_scenes/main.tscn"
@export var gameover_scene_path : String = "res://Scenes/game_over.tscn"

# Señales que otras partes del proyecto pueden escuchar
signal scene_changed(new_scene_name : String)
signal game_started()
signal game_over(score : int)

func _ready() -> void:
	# si quieres arrancar en Intro:
	go_to_intro()

# -------------------------
# API pública
# -------------------------
func go_to_intro() -> void:
	_change_scene_to_file(intro_scene_path)
	state = State.INTRO
	emit_signal("scene_changed", "Intro")

func go_to_menu() -> void:
	print("Cambio a Menu")
	_change_scene_to_file(menu_scene_path)
	state = State.MENU
	emit_signal("scene_changed", "Menu")

func start_game() -> void:
	# limpia estado de partida si es necesario
	_change_scene_to_file(game_scene_path)
	state = State.PLAYING
	emit_signal("game_started")

func go_to_gameover(score := 0) -> void:
	_change_scene_to_file(gameover_scene_path)
	state = State.GAMEOVER
	emit_signal("game_over", score)
	emit_signal("scene_changed", "GameOver")

# -------------------------
# Funciones internas
# -------------------------
func _change_scene_to_file(path : String) -> void:
	# método simple de cambio. Si quieres transiciones, mira nota abajo.
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("GameManager: error changing scene to %s - error %s" % [path, str(err)])
