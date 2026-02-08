class_name MissionButton extends TextureButton

signal mission_pressed(mission: Mission)

var mission: Mission


@export var on_course_texture : Texture2D 
@export var on_course_texture_hover : Texture2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _pressed() -> void:
	emit_signal("mission_pressed", mission)
	
func start_blinking() -> void:
	if anim.is_playing():
		return
	anim.play("blink")
	
func stop_blinking() -> void:
	anim.stop()

func set_on_course() -> void:
	start_blinking()
	self.disabled = true
	self.texture_normal = self.on_course_texture
	self.texture_hover = self.on_course_texture_hover

func set_resolved() -> void:
	stop_blinking()
	self.disabled = false

func set_warning() -> void:
	start_blinking()
