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
@export var skip_action : String = "skip_intro"
@onready var intro_label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_index := 0
var animating := false

func _ready():
	$AudioStreamPlayer.play()
	_show_paragraph(current_index)

func _show_paragraph(index: int):
	print("Intro video: %s --> %s [%s]" % 
		[index, paragraphs.size(), index >= paragraphs.size()])
	if index >= paragraphs.size():
		GameManager.go_to_menu()
		return
	intro_label.text = paragraphs[index]
	animation_player.play("fade")
	await animation_player.animation_finished
	_on_next_paragraph()

func _on_next_paragraph():
	current_index += 1
	_show_paragraph(current_index)
	
func _unhandled_input(event):
	# detectamos la pulsación de la acción skip (mejor en un handled/unhandled para UI)
	if event is InputEventMouseButton:
		if event.pressed:
			_on_next_paragraph()
	if event.is_action_pressed(skip_action):
		GameManager.go_to_menu()
