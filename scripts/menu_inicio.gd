extends Control

var tutorial_window = preload("res://tutorial.tscn").instantiate()
var creditos_window = preload("res://creditos.tscn").instantiate()

func _ready():
	# Conectar botones
	$MarginContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MarginContainer/VBoxContainer/TutorialButton.pressed.connect(_on_tutorial_pressed)
	$MarginContainer/VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$MarginContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)
	
	add_child(tutorial_window)
	add_child(creditos_window)
	# Centrar en la ventana
	tutorial_window.position = (get_viewport_rect().size - tutorial_window.size) / 2
	creditos_window.position = (get_viewport_rect().size - tutorial_window.size) / 2
	# Conectar el botón después de que la escena se haya instanciado
	tutorial_window.connect_close_button()
	creditos_window.connect_close_button()

	
func _on_new_game_pressed():
	# Carga la escena principal del juego
	get_tree().change_scene_to_file("res://Intro_Video.tscn")

func _on_tutorial_pressed():
	# Mostrar la ventana
	tutorial_window.show()

func _on_credits_pressed():
	creditos_window.show()

func _on_exit_pressed():
	get_tree().quit()
