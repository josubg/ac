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

func set_on_course() -> void:
	start_blinking()
	self.disabled = true
	self.modulate = Color(0.459, 0.18, 0.18)

func set_resolved() -> void:
	stop_blinking()
	self.disabled = false
	self.modulate= Color(0.0, 7.307, 6.021)	

func set_warning() -> void:
	start_blinking()
