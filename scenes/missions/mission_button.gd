class_name MissionButton extends TextureButton

signal mission_pressed(mission: Mission)

var mission: Mission


@export var on_course_texture : Texture2D 
@export var on_course_texture_hover : Texture2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _pressed() -> void:
	emit_signal("mission_pressed", mission)
	
## Con «reducir movimiento» el lacre no parpadea: se queda iluminado.
const STEADY_HIGHLIGHT := Color(1.25, 1.12, 1.0)

func start_blinking() -> void:
	if not Juice.motion_enabled():
		anim.stop()
		modulate = STEADY_HIGHLIGHT
		return
	if anim.is_playing():
		return
	anim.play("blink")
	anim.speed_scale = 1
	
	
func stop_blinking() -> void:
	anim.stop()
	modulate = Color.WHITE

func set_on_course() -> void:
	start_blinking()
	anim.speed_scale = 0.5
	self.disabled = true
	self.texture_normal = self.on_course_texture
	self.texture_hover = self.on_course_texture_hover

func set_resolved() -> void:
	stop_blinking()
	self.disabled = false

func set_warning() -> void:
	start_blinking()
