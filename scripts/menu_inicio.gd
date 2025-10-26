extends Control

func _ready():
	# Conectar botones
	$MarginContainer/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MarginContainer/VBoxContainer/TutorialButton.pressed.connect(_on_tutorial_pressed)
	$MarginContainer/VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$MarginContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)

func _on_new_game_pressed():
	# Carga la escena principal del juego
	get_tree().change_scene_to_file("res://main_scene.tscn")

func _on_tutorial_pressed():
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://scenes/Credits.tscn")

func _on_exit_pressed():
	get_tree().quit()
