extends Node

@onready var mission_window: Control = $CanvasLayerMission/MissionWindow
@onready var mission_resolution_window: Control = $CanvasLayerMission/MissionResolutionWindow

@onready var time_label: Label = $CanvasLayerMission/HUD/TopBar/DatePanel/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayerMission/HUD/BottomPanel/BottomRows/BottomBar/InfluencePanel/InfluenceRows/KingRow/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayerMission/HUD/BottomPanel/BottomRows/BottomBar/InfluencePanel/InfluenceRows/NobilityRow/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayerMission/HUD/BottomPanel/BottomRows/BottomBar/InfluencePanel/InfluenceRows/ClergyRow/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayerMission/HUD/TopBar/DiscontentPanel/DiscontentRow/DescontentoBar
@onready var buttons_layer: Control = $CanvasLayerMission/HUD/ButtonsLayer
@onready var riqueza_label: Label = $CanvasLayerMission/HUD/TopBar/WealthPanel/WealthRow/RiquezaLabel
@onready var riqueza_mod_label: Label = $CanvasLayerMission/HUD/TopBar/WealthPanel/WealthRow/RiquezaModLabel

@onready var active_missions: Dictionary[Mission, int] = {}
@onready var active_mission_buttons: Dictionary[Mission, MissionButton] = {}
@onready var monja_speak: Node = $CanvasLayerMission/MonjaSpeak
@onready var gomez_speak: Node = $CanvasLayerMission/GomezSpeak
@onready var audio_descontento: AudioStreamPlayer = $AudioDescontento

#Buildings
@onready var buildings_container: Node2D = $Buildings
@onready var building_node_scene: PackedScene = load(
	"res://scenes/buildings/building_node.tscn"
)
@onready var properties_button: Button = $CanvasLayerMission/HUD/TopBar/WealthPanel/WealthRow/PropertiesButton
@onready var properties_window: PropertiesWindow = $CanvasLayerMission/PropertiesWindow

@onready var building_window: Control = $CanvasLayerMission/BuildingWindow

@onready var mission_button_scene: PackedScene = load("res://scenes/missions/mission_button.tscn")
const BASE_RES = Vector2(1920, 1080)

var buttons: Array[MissionButton]= []
# Mensajes con bocadillo (la monja, Juan Gómez...). Solo uno en pantalla: el
# resto espera en una cola común como pares [personaje, clave].
var mensaje_en_pantalla := false
var cola_mensajes: Array = []
var _hablante: Node = null
var gomez_presentado := false
var descontento_playing = false

func _ready() -> void:
	Player.clero_updated.connect(update_clero)
	Player.nobleza_updated.connect(update_nobleza)
	Player.rey_updated.connect(update_rey)
	Player.descontento_updated.connect(update_descontento)
	Player.rey_strike.connect(rey_strikes)
	Player.noble_strike.connect(nobleza_strikes)
	Player.iglesia_strike.connect(iglesia_strikes)
	Player.riqueza_updated.connect(update_riqueza)
	
	MissionManager.added_mission.connect(mission_added)
	MissionManager.warning_mission.connect(mission_updated)
	MissionManager.closed_mission.connect(mission_removed)
	
	create_buildings()

	update_rey(Player.rey)
	update_nobleza(Player.nobleza)
	update_clero(Player.clero)
	update_descontento(Player.descontento)
	update_riqueza(Player.riqueza)
	
	monja_speak.ocultar()
	gomez_speak.ocultar()
	properties_button.pressed.connect(_on_properties_button_pressed)
	Juice.attach_main(self) # FX: feedback de la partida (scripts/fx/main_juice.gd)

func _process(_delta):
	if GameManager.playing():
		time_label.text = TimeManager.get_date()
		if TimeManager.get_elapsed_days() >= 5 and not gomez_presentado:
			_show_gomez_message()
		if MissionManager.mission_count == 0:
			GameManager.go_to_gameend()

func _input(event: InputEvent) -> void:
	if mensaje_en_pantalla:
		var closes_message: bool = (
			(event is InputEventKey or event is InputEventMouseButton)
			and event.pressed
		)
		if closes_message:
			_close_message()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_pointer_over_ui():
			return
		var mouse_world: Vector2 = (
			get_viewport().get_canvas_transform().affine_inverse()
			* event.position
		)

		var query := PhysicsPointQueryParameters2D.new()
		query.position = mouse_world
		query.collision_mask = 1
		query.collide_with_areas = true
		query.collide_with_bodies = false

		var results: Array[Dictionary] = (
			get_viewport()
			.get_world_2d()
			.direct_space_state
			.intersect_point(query)
		)

		for result in results:
			var collider = result["collider"]
			if collider is BuildingNode:
				_on_building_pressed(collider.building)
				get_viewport().set_input_as_handled()
				break

# Los clics en edificios se procesan en _input (antes que la interfaz), así que hay
# que descartar a mano los que caen sobre una ventana o un control de la UI.
func _is_pointer_over_ui() -> bool:
	for window: Control in [mission_window, mission_resolution_window, building_window, properties_window]:
		if window.visible:
			return true
	var hovered: Control = get_viewport().gui_get_hovered_control()
	return hovered != null and hovered != buttons_layer

func _show_monja_message(text: String) -> void:
	_show_message(monja_speak, text)

# Si ya hay un mensaje en pantalla, sea de quien sea, el nuevo espera su turno.
func _show_message(speaker: Node, text: String) -> void:
	if mensaje_en_pantalla:
		cola_mensajes.append([speaker, text])
		return
	TimeManager.pause(&"bocadillo")
	_hablante = speaker
	speaker.mensaje(text)
	mensaje_en_pantalla = true

func _close_message() -> void:
	_hablante.ocultar()
	mensaje_en_pantalla = false
	if not cola_mensajes.is_empty():
		var siguiente: Array = cola_mensajes.pop_front()
		_show_message(siguiente[0], siguiente[1])
		return
	TimeManager.resume(&"bocadillo")

func mission_added(mission: Mission) -> void:
	DebugLog.log("Main: Mision added:  [%s]" % mission.titulo)
	var button: MissionButton = mission_button_scene.instantiate()
	buttons.append(button)
	buttons_layer.add_child(button)
	var vp_size = get_viewport().get_visible_rect().size
	var pos = Vector2((mission.x / BASE_RES.x) * vp_size.x,(mission.y / BASE_RES.y) * vp_size.y)
	pos = _free_button_position(pos, button)
	button.position = pos
	DebugLog.log("Main: [X %s, Y %s] --> [X %s, Y %s]" % 
		[mission.x,mission.y,pos.x,pos.y])
	button.mission = mission
	button.mission_pressed.connect(_on_mission_pressed)
	
# Varias misiones comparten coordenadas en el CSV; si el sitio está ocupado por
# otro lacre, se coloca alrededor para que no se tapen.
func _free_button_position(pos: Vector2, new_button: MissionButton) -> Vector2:
	const MIN_DISTANCE := 48.0
	var candidate := pos
	for attempt in 12:
		var taken := false
		for other in buttons:
			if other != new_button and other.position.distance_to(candidate) < MIN_DISTANCE:
				taken = true
				break
		if not taken:
			return candidate
		candidate = pos + Vector2.RIGHT.rotated(attempt * TAU / 6.0) * MIN_DISTANCE * (1 + attempt / 6)
	return candidate

func mission_updated(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			if mission.on_course():
				button.set_on_course()
			if mission.resolved():
				button.set_resolved()
			else:
				button.set_warning()

func mission_removed(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			buttons_layer.remove_child(button)
			buttons.erase(button)
			button.queue_free()

func update_rey(value):
	rey_bar.value = value
	_update_color(rey_bar, value,false)

func update_nobleza(value):
	nobleza_bar.value = value
	_update_color(nobleza_bar,value,false)

func update_clero(value):
	clero_bar.value = value
	_update_color(clero_bar, value,false)

func update_riqueza(value):
	riqueza_label.text = LocaleSettings.format_int(value)
	update_mod_riqueza()
	
func update_mod_riqueza():
	var breakdown = BuildingManager.get_player_income_breakdown()
	if breakdown != {}:
		riqueza_mod_label.text = tr("UI_HUD_INCOME_PER_DAY") % LocaleSettings.format_int(breakdown["total"])
	
func update_descontento(value):
	descontento_bar.value = value
	audio_descontento.volume_db = value-116
	DebugLog.log("VOLUME:"+str(audio_descontento.volume_db))
	if descontento_bar.value > 70 and not descontento_playing:
		audio_descontento.play()
		descontento_playing = true
	elif descontento_bar.value < 70:
		audio_descontento.stop()
		descontento_playing = false
	_update_color(descontento_bar,value,true)

const COLOR_PELIGRO := Color("9a2a22")

func _update_color(faction : ProgressBar, value: float, inverse: bool) -> void:
	# Cada barra conserva su color heráldico (definido en main.tscn) y vira
	# hacia el rojo lacre a medida que la situación se vuelve peligrosa.
	if not faction.has_meta("relleno_base"):
		faction.set_meta("relleno_base", faction.get_theme_stylebox("fill"))
	var base: StyleBoxFlat = faction.get_meta("relleno_base")
	var ratio := value / 100.0
	var peligro := ratio if inverse else 1.0 - ratio
	var style: StyleBoxFlat = base.duplicate()
	style.bg_color = base.bg_color.lerp(COLOR_PELIGRO, clampf((peligro - 0.5) / 0.35, 0.0, 1.0))
	faction.add_theme_stylebox_override("fill", style)
	
func _on_mission_pressed(mission: Mission) -> void:
	if mission.resolved():
		mission_resolution_window.show_mission(mission)
	else:
		mission_window.show_mission(mission)
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			$PauseMenu.open()

func rey_strikes(number):
	if number == 1:
		_show_monja_message("MONJA_REY_1")
	if number == 2:
		_show_monja_message("MONJA_REY_2")
	if number == 3:
		_show_monja_message("MONJA_REY_3")


func nobleza_strikes(number):
	if number == 1:
		_show_monja_message("MONJA_NOBLEZA_1")
	if number == 2:
		_show_monja_message("MONJA_NOBLEZA_2")
	if number == 3:
		_show_monja_message("MONJA_NOBLEZA_3")
		
func iglesia_strikes(number):
	if number == 1:
		_show_monja_message("MONJA_IGLESIA_1")
	if number == 2:
		_show_monja_message("MONJA_IGLESIA_2")
	if number == 3:
		_show_monja_message("MONJA_IGLESIA_3")

func create_buildings() -> void:
	var vp_size = get_viewport().get_visible_rect().size
	
	for building in BuildingManager.buildings:
		var building_node: BuildingNode = building_node_scene.instantiate()

		var pos = Vector2(
			(building.x / BASE_RES.x) * vp_size.x,
			(building.y / BASE_RES.y) * vp_size.y
		)

		building_node.position = pos
		building_node.building = building

		buildings_container.add_child(building_node)

func _on_building_pressed(building: Building) -> void:
	building_window.setup(building)

func _on_properties_button_pressed() -> void:
	properties_window.setup()

# Juan Gómez se presenta el día en que se une (available_from_day = 5).
func _show_gomez_message() -> void:
	gomez_presentado = true
	for key in ["GOMEZ_1", "GOMEZ_2", "GOMEZ_3"]:
		_show_message(gomez_speak, key)
