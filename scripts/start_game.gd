extends Node

func _ready() -> void:
	# el GameManager ya está disponible como singleton
	# puedes hacer checks, mostrar splash, o directamente iniciar:
	GameManager.go_to_intro()  # o GameManager.go_to_menu()
