class_name MissionButton extends TextureButton

signal mission_pressed(mission: Mission)

@export var mission: Mission

@onready var anim: AnimationPlayer = $AnimationPlayer

func _pressed() -> void:
	emit_signal("mission_pressed", mission)

func start_blinking() -> void:
	if anim.is_playing():
		return
	anim.play("blink")

func stop_blinking() -> void:
	anim.stop()
	modulate = Color.WHITE

func set_gold() -> void:
	modulate= Color(0.0, 7.307, 6.021)
