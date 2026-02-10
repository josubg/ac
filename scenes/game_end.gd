extends Control


@export var paragraphs := [
	"No me destierran, sigo en mi destino, la Corte me sostiene en su quimera;\n mas veo al Reino hundirse en su carrera,\n pues manda el oro más que el buen camino.",
	"De Valido pasé a señor divino, con títulos, favores y bandera;\n pero la nave imperial ya desespera, se pudre el mástil, se corrompe el lino.",
	"Los grandes callan, el vulgo se lamenta,\n España se consume en su desgracia,\n la gloria antigua es sombra que se ausenta.",
	"Y yo, aún con poder, guardo mi audacia:\n si el Imperio se hunde y nada lo sustenta,\n no es mi caída: es su propia falacia."
]

@export var fade_duration := 1.0        # segundos para aparecer/desaparecer
@export var display_duration := 8     # cuánto tiempo se muestra cada párrafo
@export var next_scene_path := "res://main_scene.tscn"
@export var skip_action : String = "skip_intro"
@onready var intro_label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label_go: Label = $LabelGO

var current_index := 0
var animating := false

func _ready():
	$AudioStreamPlayer.play()
	_show_paragraph(current_index)
	label_go.hide()
	

func _show_paragraph(index: int):
	print("Game end: %i --> %i [%b]" % 
		[index, paragraphs.size(), index >= paragraphs.size()])
	if index >= paragraphs.size():
		label_go.show()
		intro_label.hide()
		animation_player.play("fade")
		await animation_player.animation_finished
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
	if event.is_action_pressed(skip_action):
		GameManager.go_to_menu()
