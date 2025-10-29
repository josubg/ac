extends Panel
class_name Agent


@export var full_name: String
@export var selected: Texture2D
@export var unselected: Texture2D
@export var biografy: String
@export var faccion: String

@export var noble: bool
@export var cura: bool
@export var malechor: bool

@onready var stats_panel: Panel = $StatsPanel
var mouse_over := false

 

var assigned: bool :
	set(value):
		assigned = value
		if value:
			$Portrait.texture = self.unselected
		else:
			$Portrait.texture = self.selected


func _ready() -> void:
	self.assigned = false
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if noble:
		faccion = "Noble"
	elif cura:
		faccion = "Religiosa"
	else:
		faccion = "Malechor"

func _update_stats_text():
	$StatsPanel/Label.text = full_name + "\n" + "("+faccion+")"

func _get_drag_data(_position):
	if self.assigned:
		print("Draging Null")
		return null
	# Crea un control visual que servirá como "preview" durante el arrastre
	print("Draging Agent")
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = $Portrait.texture
	preview.custom_minimum_size = Vector2(64, 64)  # opcional
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	set_drag_preview(preview)
	return self

func _on_mouse_entered():
	_update_stats_text()
	show_stats()

func _on_mouse_exited():
	hide_stats()

func show_stats():
	stats_panel.visible = true
	stats_panel.modulate.a = 0.0
	var tween := get_tree().create_tween()
	tween.tween_property(stats_panel, "modulate:a", 1.0, 0.3)

func hide_stats():
	var tween := get_tree().create_tween()
	tween.tween_property(stats_panel, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): stats_panel.visible = false)
	
