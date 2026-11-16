class_name Agent extends Panel

enum AGENT_STATUS {AVAILABLE, DRAGGED, ASSIGNED, DEPLOYED, RESTING}

@export var full_name: String
@export var assigned_texture: Texture2D
@export var available_texture: Texture2D
@export var biography: String
@export var rest_time: int = 30
@export_enum(Factions.noble, Factions.cura, Factions.malechor) var faction: String
@export var available_from_day: int = 1

@onready var label: Label = $StatsPanel/Label
@onready var portrait: TextureRect = $Portrait
@onready var stats_panel: Panel = $StatsPanel
@onready var timer: Timer = $Timer
@onready var label_2: Label = $StatsPanel/Label2

var experiencia : int = 0
var missiones_veterano: int =  4

var veterano: bool :
	get(): 
		return experiencia > missiones_veterano

var status: AGENT_STATUS = AGENT_STATUS.AVAILABLE :
	set(value):
		status = value
		if value == AGENT_STATUS.AVAILABLE:
			$Portrait.texture = self.available_texture
		else:
			$Portrait.texture = self.assigned_texture
		_show_availability()

var available: bool: 
	get():
		return self.status == AGENT_STATUS.AVAILABLE

func _process(_delta: float) -> void:
	if not visible and TimeManager.get_elapsed_days() >= available_from_day:
		show()
		
func _ready() -> void:
	label.text = full_name
	label_2.text = "AGENT_FACTION_" + faction.to_upper()
	portrait.texture = available_texture
	visible = TimeManager.get_elapsed_days() >= available_from_day
	_show_availability()
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

## Presentación: un agente ocupado se ve apagado, con cursor de prohibido y un aviso.
func _show_availability() -> void:
	var free := status == AGENT_STATUS.AVAILABLE
	$Portrait.self_modulate = Color.WHITE if free else Color(0.55, 0.5, 0.45)
	mouse_default_cursor_shape = Control.CURSOR_DRAG if free else Control.CURSOR_FORBIDDEN
	tooltip_text = "" if free else "UI_AGENT_BUSY"

func unselect():
	# When agent is removed from unstarted mission
	self.status = AGENT_STATUS.AVAILABLE
	
func send_home(exito: bool):
	if exito:
		self.experiencia += 1
	self.rested()
	#self.status = AGENT_STATUS.RESTING
	#timer.timeout.connect(self.rested)
	#timer.start(rest_time)
	#TimeManager.add_timer(timer)

func rested():
	#TimeManager.remove_timer(timer)
	self.status = AGENT_STATUS.AVAILABLE

func _notification(what: int) -> void:
	# DRAG_END llega a todos los controles, no solo al arrastrado: sin comprobar
	# DRAGGED, soltar cualquier agente en el vacío liberaba también a los que
	# estaban de misión y volvían a la barra antes de resolverse.
	if what == NOTIFICATION_DRAG_END and status == AGENT_STATUS.DRAGGED \
			and not get_viewport().gui_is_drag_successful():
		DebugLog.log("Agent: Drag failed [%s]" % self.full_name)
		self.status = AGENT_STATUS.AVAILABLE

func _get_drag_data(_position) -> Variant:
	if not available:
		return null

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
	
func generate_drag_portrait() -> Control:
	return DragPreview.build(portrait.texture)
