extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	LocaleSettings.apply_saved()
	animation_player.play("fade")
	await animation_player.animation_finished
	GameManager.go_to_intro_video()
