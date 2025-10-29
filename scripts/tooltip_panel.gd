extends Panel

@onready var label: Label = $Label
@onready var anim: AnimationPlayer = $AnimationPlayer

func show_tooltip(text: String):
	label.text = text
	visible = true
	modulate.a = 0.0
	anim.play("fade_in")

func hide_tooltip():
	if visible:
		anim.play("fade_out")
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_out":
		visible = false
