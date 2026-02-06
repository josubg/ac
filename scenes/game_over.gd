extends Control

@export var paragraphs := [
	"Me echan de la corte, ¡vaya desatino!, que ayer mandaba yo sobre la tierra;\n hoy mando solo al burro que me lleva, camino de destierro, peregrino.",
	"De Valido pasé a vecino indigno, sin Corte, sin poder, sin tanta guerra;\n y aunque mi honra se arruga y se destierra,\n me queda lengua para hacer el pino.",
	"Los grandes ríen, el vulgo se carcajea, \ndicen que el Conde-Duque ya no vale, \nque su privanza fue comedia fea.",
	"Mas yo respondo, con sorna y con detalle:\n si el Reino arde y la Corte tambalea,\n ¡no fue mi culpa, fue su carnaval de baile!"
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
	print(str(index) + "-->" + str(paragraphs.size()))
	print(index >= paragraphs.size())
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
