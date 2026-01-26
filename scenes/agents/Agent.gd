class_name Agent extends Panel

@export var full_name: String
@export var selected: Texture2D
@export var unselected: Texture2D
@export var biografy: String

@onready var portrait: TextureRect = $Portrait
@onready var stats_panel: Panel = $StatsPanel

enum agent_status {READY, DRAGED, ASSIGNED, DEPLOYED, RESTING}

@export_enum(Factions.noble, Factions.cura, Factions.malechor) var faction: String :
	set(value):
		stats_panel.text = full_name + "\n" + "("+faction+")"

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
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not get_viewport().gui_is_drag_successful():
		# Drag failed
		print("Drag failed" , self.full_name)


func _get_drag_data(_position):
	if self.assigned:
		return null
	var drag_portrait = generate_drag_portrait()
	set_drag_preview(drag_portrait)
	return self

func _on_mouse_entered():
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
	
func generate_drag_portrait():
	var preview = TextureRect.new()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = portrait.texture
	preview.custom_minimum_size = Vector2(64, 64)  # opcional
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.z_index= 1000
	return preview
