extends CanvasLayer

@onready var anim = $AnimationPlayer

func _ready():
	anim.play("fate_to_black")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fate_to_black":
		get_tree().change_scene_to_file("res://menu_inicio.tscn")
