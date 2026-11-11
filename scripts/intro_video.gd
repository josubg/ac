extends Control

@export var paragraphs := [
	"INTRO_1",
	"INTRO_2",
	"INTRO_3",
	"INTRO_4",
	"INTRO_5"
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
