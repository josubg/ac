class_name MissionButton extends TextureButton

signal mission_pressed(mission: Mission)

var mission: Mission

@onready var anim: AnimationPlayer = $AnimationPlayer

func setup(m: Mission) -> void:
	mission = m

func _pressed() -> void:
	emit_signal("mission_pressed", mission)


func _on_pressed() -> void:
	emit_signal("mission_pressed", mission)

func start_blinking() -> void:
	if anim.is_playing():
		return
	anim.play("blink")

func stop_blinking() -> void:
	anim.stop()
	modulate = Color.WHITE
