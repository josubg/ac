extends Control

@export var paragraphs := [
	"Año del Señor de 1640.",
	"En la augusta corte de Su Majestad Felipe IV, el Imperio Español, otrora vasto y temido, comienza a crujir bajo el peso de su propia grandeza. ",
	"En medio de tales turbulencias, el conde-duque de Olivares, valido de Su Majestad y guardián de los secretos del reino, gobierna no sólo con la pluma y la espada, sino con el silencio y la sospecha.",
	"Su deber es sostener el velo de la influencia y el descontento. Pues en Madrid, cuatro fuerzas invisibles mueven los hilos del poder: la Iglesia, la Nobleza, la Burguesía, y la Plebe.",
	"Entre ellos, el conde-duque ha de tejer su red de mentiras y verdades, sabiendo que en la corte de España, la lealtad es una moneda tan rara como el oro que falta en sus cofres."
]

@export var fade_duration := 1.0        # segundos para aparecer/desaparecer
@export var display_duration := 6     # cuánto tiempo se muestra cada párrafo
@export var next_scene_path := "res://main_scene.tscn"

var current_index := 0
var animating := false

func _ready():
	_show_paragraph(current_index)
	$AudioStreamPlayer.play()

func _show_paragraph(index: int):
	if index >= paragraphs.size():
		get_tree().change_scene_to_file(next_scene_path)
		return

	$Label.text = paragraphs[index]
	animating = true

	var anim_player = $AnimationPlayer

	# Creamos la animación fade
	var anim := Animation.new()
	anim.length = fade_duration * 2 + display_duration

	var track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Label:modulate:a")
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, fade_duration, 1.0)
	anim.track_insert_key(track, fade_duration + display_duration, 1.0)
	anim.track_insert_key(track, anim.length, 0.0)

	# Creamos o usamos la AnimationLibrary del player
	if not anim_player.has_animation_library("default"):
		var lib := AnimationLibrary.new()
		anim_player.add_animation_library("default", lib)

	var lib: AnimationLibrary = anim_player.get_animation_library("default")
	if lib.has_animation("fade"):
		lib.remove_animation("fade")
	lib.add_animation("fade", anim)

	anim_player.call_deferred("play", "fade")

	$Timer.wait_time = anim.length
	if $Timer.timeout.is_connected(_on_next_paragraph):
		$Timer.timeout.disconnect(_on_next_paragraph)
	$Timer.timeout.connect(_on_next_paragraph, CONNECT_ONE_SHOT)
	$Timer.start()

func _on_next_paragraph():
	current_index += 1
	_show_paragraph(current_index)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if animating:
			$AnimationPlayer.stop()
			$Label.modulate.a = 1.0
			$Timer.stop()
			animating = false
			$Timer.start(display_duration)
		else:
			_on_next_paragraph()
