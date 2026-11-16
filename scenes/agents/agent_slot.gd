class_name AgentSelector extends PanelContainer

@onready var portrait: TextureRect = $Portrait
@onready var frame: NinePatchRect = $Marco
@export var void_texture: Texture2D 

var mission : Mission
var agent: Agent

## Brillo del marco: en reposo, hueco disponible durante un arrastre, hueco bajo el cursor.
const FRAME_IDLE := Color(1, 1, 1)
const FRAME_READY := Color(1.2, 1.08, 0.85)
const FRAME_HOVER := Color(1.9, 1.6, 0.95)

func _ready() -> void:
	self.set_drag_forwarding(self.drag,self.can_drop_data,self.drop_data)
	mouse_exited.connect(_on_mouse_exited)
	_update_cursor()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			if get_viewport().gui_get_drag_data() is Agent:
				_set_frame(FRAME_READY)
		NOTIFICATION_DRAG_END:
			_set_frame(FRAME_IDLE)

func _on_mouse_exited() -> void:
	if get_viewport().gui_is_dragging() and get_viewport().gui_get_drag_data() is Agent:
		_set_frame(FRAME_READY)

func _set_frame(color: Color) -> void:
	if frame:
		frame.self_modulate = color

func _update_cursor() -> void:
	mouse_default_cursor_shape = CURSOR_DRAG if agent else CURSOR_ARROW

func drag(_position):
	var old_agent = self.agent
	var drag_portrait = self.agent.generate_drag_portrait()
	set_drag_preview(drag_portrait)
	self.clean_agent()
	return old_agent

func can_drop_data(_position, data):
	var valid: bool = data is Agent
	if valid:
		_set_frame(FRAME_HOVER)
	return valid

func drop_data(_position, data: Agent):
	# Asigna el agente a este slot
	if self.agent:
		self.clean_agent()
	self.set_agent(data)

func set_agent(new_agent: Agent):
	mission.set_agent(new_agent)
	self.agent = new_agent
	self.portrait.texture = agent.available_texture
	_update_cursor()
	
func clean_agent():
	mission.clean_agent(self.agent)
	self.portrait.texture = self.void_texture
	self.agent = null
	_update_cursor()
