extends Node

# Estados del juego (opcional, útil para lógica)
enum State { NONE, INTRO, MENU, PLAYING, GAMEOVER }
var state : State = State.NONE

# Rutas a escenas (ajusta según tu proyecto)
@export var intro_scene_path  : String = "res://scenes/Intro_Video.tscn"
@export var menu_scene_path   : String = "res://scenes/menu_inicio.tscn"
@export var game_scene_path   : String = "res://scenes/play_scenes/main.tscn"
@export var gameover_scene_path : String = "res://scenes/game_over.tscn"
@export var gameend_scene_path : String = "res://scenes/game_end.tscn"

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

func playing() -> bool:
	return state == State.PLAYING
	
func go_to_intro() -> void:
	print("Game Manager: Intro")
	_change_scene_to_file(intro_scene_path)
	state = State.INTRO
	emit_signal("scene_changed", "Intro")

func go_to_menu() -> void:
	print("Game Manager: Menu")
	_change_scene_to_file(menu_scene_path)
	state = State.MENU
	emit_signal("scene_changed", "Menu")

func start_game() -> void:
	print("Game Manager: Start game")
	# limpia estado de partida si es necesario
	_change_scene_to_file(game_scene_path)
	state = State.PLAYING
	emit_signal("game_started")
	MissionManager.load_missions("res://resources/data/missions.txt")
	print("Main: %s" % str(MissionManager.scheduled_missions))
	Player.start()


func go_to_gameover(score := 0) -> void:
	print("Game Manager: GAME OVER")
	_change_scene_to_file(gameover_scene_path)
	state = State.GAMEOVER
	emit_signal("game_over", score)
	emit_signal("scene_changed", "GameOver")

func go_to_gameend(score := 0) -> void:
	print("Game Manager: Game end")
	_change_scene_to_file(gameend_scene_path)
	state = State.GAMEOVER
	emit_signal("game_over", score)
	emit_signal("scene_changed", "GameEnd")
# -------------------------
# Funciones internas
# -------------------------
func _change_scene_to_file(path : String) -> void:
	# método simple de cambio. Si quieres transiciones, mira nota abajo.
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("GameManager: error changing scene to %s - error %s" % [path, str(err)])
