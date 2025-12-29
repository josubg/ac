extends TextureButton
class_name MissionButton

signal mission_pressed(mission: MissionData)

var mission: MissionData

@onready var anim: AnimationPlayer = $AnimationPlayer

func setup(m: MissionData) -> void:
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
