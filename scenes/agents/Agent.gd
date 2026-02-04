class_name Agent extends Panel

enum AGENT_STATUS {AVAILABLE, DRAGGED, ASSIGNED, DEPLOYED, RESTING}

@export var full_name: String
@export var assigned_texture: Texture2D
@export var available_texture: Texture2D
@export var biografy: String
@export var rest_time: int = 30

@onready var portrait: TextureRect = $Portrait
@onready var stats_panel: Panel = $StatsPanel
@onready var timer: Timer = $Timer


var status: AGENT_STATUS = AGENT_STATUS.AVAILABLE :
	set(value):
		status = value
		if value == AGENT_STATUS.AVAILABLE:
			$Portrait.texture = self.available_texture
		else:
			$Portrait.texture = self.assigned_texture

var available: bool: 
	get():
		return self.status == AGENT_STATUS.AVAILABLE

@export_enum(Factions.noble, Factions.cura, Factions.malechor) var faction: String :
	set(value):
		stats_panel.text = full_name + "\n" + "("+faction+")"

func _ready() -> void:
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

func unselect():
	# When agent is removed from unstarted mission
	self.status = AGENT_STATUS.AVAILABLE
	
func send_home():
	self.status = AGENT_STATUS.RESTING
	timer.timeout.connect(self.rested)
	timer.start(rest_time)
	TimeManager.add_timer(timer)

func rested():
	TimeManager.remove_timer(timer)
	self.status = AGENT_STATUS.AVAILABLE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not get_viewport().gui_is_drag_successful():
		# Drag failed
		print("Drag failed" , self.full_name)
		self.status = AGENT_STATUS.AVAILABLE

func _get_drag_data(_position):
	if self.available:
		var drag_portrait = generate_drag_portrait()
		set_drag_preview(drag_portrait)
		self.status = AGENT_STATUS.DRAGGED
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
