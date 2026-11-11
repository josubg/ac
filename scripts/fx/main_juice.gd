extends Node
## Feedback de la partida. Lo crea Juice.attach_main(main) desde main.gd y vive
## como hijo de la escena principal (se libera con ella).
##
## No modifica la lógica: solo escucha señales que ya existen (Player,
## MissionManager, visibility_changed de las ventanas, agents_changed de la
## misión) y lee las variables @onready de main.gd por nombre. Si la escena
## cambia y alguna referencia desaparece, ese efecto simplemente no se dispara.

const GOOD := Color(1.0, 0.85, 0.45)       # dorado: favorable
const BAD := Color(0.95, 0.32, 0.28)       # carmesí: desfavorable
const DANGER_THRESHOLD := 20               # == Player.strike_2
const DESCONTENTO_VIGNETTE_FROM := 60.0

var main: Node
var _last := {}                  # stat -> último valor visto
var _bars := {}                  # stat -> ProgressBar
var _button_pos := {}            # Mission -> posición de pantalla del lacre
var _glint_timers := {}          # Mission -> Timer del brillo de "listo para abrir"
var _owners := {}                # building id -> owner
var _slot_agents := {}           # AgentSelector -> Agent
var _watched_mission: Mission
var _last_day := -1
var _vignette: ColorRect
var _vignette_value := 0.0


func setup(main_node: Node) -> void:
	main = main_node
	_bars = {
		&"rey": main.get(&"rey_bar"),
		&"nobleza": main.get(&"nobleza_bar"),
		&"clero": main.get(&"clero_bar"),
		&"descontento": main.get(&"descontento_bar"),
	}
	for stat in [&"rey", &"nobleza", &"clero", &"descontento", &"riqueza"]:
		_last[stat] = Player.get(stat)
	for building in BuildingManager.buildings:
		_owners[building.id] = building.owner
	_last_day = TimeManager.last_day

	# Señales del modelo. main.gd se conecta antes en su _ready, así que cuando
	# llegan aquí el botón del lacre ya existe (o ya se ha borrado).
	Player.rey_updated.connect(_on_stat.bind(&"rey"))
	Player.nobleza_updated.connect(_on_stat.bind(&"nobleza"))
	Player.clero_updated.connect(_on_stat.bind(&"clero"))
	Player.descontentoy_updated.connect(_on_stat.bind(&"descontento"))
	Player.riqueza_updated.connect(_on_riqueza)
	Player.rey_strike.connect(_on_strike.bind(&"rey"))
	Player.noble_strike.connect(_on_strike.bind(&"nobleza"))
	Player.iglesia_strike.connect(_on_strike.bind(&"clero"))
	MissionManager.added_mission.connect(_on_mission_added)
	MissionManager.warning_mission.connect(_on_mission_updated)
	MissionManager.clossed_mission.connect(_on_mission_closed)

	# Ventanas (aparecen con show()/hide()).
	for key in [&"mission_window", &"mission_resolution_window", &"building_window", &"properties_window"]:
		var window: CanvasItem = main.get(key)
		if window:
			window.visibility_changed.connect(_on_window_visibility.bind(window, key))

	# Mensaje de la monja: monja_speak.mensaje() hace show() del Label.
	var monja: Node = main.get(&"monja_speak")
	if monja and monja.has_node(^"Label"):
		monja.get_node(^"Label").visibility_changed.connect(_on_monja_visibility.bind(monja))

	_build_vignette()
	_build_world_fx()
	_update_danger(true)


func _exit_tree() -> void:
	# Las señales de autoloads sobreviven a la escena: desconectar.
	for pair in [
		[Player.rey_updated, _on_stat], [Player.nobleza_updated, _on_stat],
		[Player.clero_updated, _on_stat], [Player.descontentoy_updated, _on_stat],
		[Player.riqueza_updated, _on_riqueza], [Player.rey_strike, _on_strike],
		[Player.noble_strike, _on_strike], [Player.iglesia_strike, _on_strike],
		[MissionManager.added_mission, _on_mission_added],
		[MissionManager.warning_mission, _on_mission_updated],
		[MissionManager.clossed_mission, _on_mission_closed],
	]:
		var sig: Signal = pair[0]
		for c in sig.get_connections():
			if c.callable.get_object() == self:
				sig.disconnect(c.callable)


func _process(_delta: float) -> void:
	# Paso de los días: TimeManager no emite señal, se mira last_day.
	if TimeManager.last_day != _last_day:
		var first := _last_day == -1
		_last_day = TimeManager.last_day
		if not first:
			_on_new_day()


# --- Lacres en el mapa -----------------------------------------------------------

func _button_for(mission: Mission) -> MissionButton:
	for button in main.get(&"buttons"):
		if is_instance_valid(button) and button.mission == mission:
			return button
	return null


func _on_mission_added(mission: Mission) -> void:
	var button := _button_for(mission)
	if button == null:
		return
	_button_pos[mission] = Juice.screen_center(button)
	Juice.drop_in(button)
	_after(0.18, func():
		var p: Vector2 = _button_pos.get(mission, Vector2.ZERO)
		Juice.burst(p, &"dust")
		Juice.ripple(p, 0.6, 0.6)
		Juice.sfx(&"seal", -3.0))


func _on_mission_updated(mission: Mission) -> void:
	var button := _button_for(mission)
	if button == null:
		return
	_button_pos[mission] = Juice.screen_center(button)
	var pos: Vector2 = _button_pos[mission]
	match mission.status:
		Mission.MISSION_STATUS.warning:
			# A punto de caducar: late como un corazón; un roce de papel avisa.
			Juice.pulse_loop(button, true)
			Juice.sfx(&"paper", -6.0, 0.8)
		Mission.MISSION_STATUS.on_course:
			# Enviada: el sello golpea el papel y deja un anillo de tinta.
			Juice.pulse_loop(button, false)
			Juice.squash(button)
			Juice.burst(pos, &"stamp")
			Juice.ripple(pos, 1.0, 0.7)
			Juice.sfx(&"seal", 0.0, 0.9)
		Mission.MISSION_STATUS.succeded, Mission.MISSION_STATUS.failed:
			# Resuelta: brilla de vez en cuando para invitar a abrirla.
			Juice.pop(button, 0.25)
			Juice.burst(pos, &"glint")
			Juice.sfx(&"paper", -4.0, 1.2)
			_start_glint(mission)


func _on_mission_closed(mission: Mission) -> void:
	_stop_glint(mission)
	var pos: Vector2 = _button_pos.get(mission, Vector2.ZERO)
	_button_pos.erase(mission)
	if mission.status == Mission.MISSION_STATUS.expired and pos != Vector2.ZERO:
		# Caducada: el lacre se resquebraja.
		Juice.burst(pos, &"wax")
		Juice.burst(pos, &"dust", 0.6)
		Juice.ripple(pos, 0.8, 0.6)
		Juice.sfx(&"crack", -1.0)
		Juice.shake(0.18)
		Juice.grade_pulse(0.25, 0.1, 0.8)


func _start_glint(mission: Mission) -> void:
	_stop_glint(mission)
	var timer := Timer.new()
	timer.wait_time = 1.8
	add_child(timer)
	timer.timeout.connect(func():
		if _button_pos.has(mission) and not TimeManager.paused:
			Juice.burst(_button_pos[mission], &"glint", 0.8))
	timer.start()
	_glint_timers[mission] = timer


func _stop_glint(mission: Mission) -> void:
	if _glint_timers.has(mission):
		_glint_timers[mission].queue_free()
		_glint_timers.erase(mission)


# --- Barras de facción -----------------------------------------------------------

func _on_stat(value: int, stat: StringName) -> void:
	var old: int = _last.get(stat, value)
	_last[stat] = value
	var delta := value - old
	_check_buildings()
	if delta == 0:
		return
	var bar: ProgressBar = _bars.get(stat)
	if bar == null or not is_instance_valid(bar):
		return
	var good := delta < 0 if stat == &"descontento" else delta > 0
	var color := GOOD if good else BAD
	Juice.flash(bar, Color(1.5, 1.35, 0.9) if good else Color(1.6, 0.6, 0.55), 0.5)
	if absi(delta) >= 2:
		var pos := Juice.screen_center(bar) + Vector2(bar.size.x * 0.25, -bar.size.y * 0.6)
		Juice.float_text(pos, ("+%d" if delta > 0 else "−%d") % absi(delta), color)
	if absi(delta) >= 10:
		Juice.pop(bar, 0.06, 0.3)
	if stat == &"descontento":
		_update_vignette(value)
	_update_danger()


## Barra en zona de peligro (< 20, el segundo aviso): late en rojo.
func _update_danger(force: bool = false) -> void:
	for stat in [&"rey", &"nobleza", &"clero"]:
		var bar: ProgressBar = _bars.get(stat)
		if bar == null or not is_instance_valid(bar):
			continue
		var danger: bool = _last[stat] < DANGER_THRESHOLD
		if danger == bar.has_meta(&"_juice_danger") and not force:
			continue
		if danger:
			bar.set_meta(&"_juice_danger", true)
			var tw := bar.create_tween().set_loops()
			tw.tween_property(bar, ^"modulate", Color(1.35, 0.7, 0.65), 0.5)
			tw.tween_property(bar, ^"modulate", Color.WHITE, 0.7)
			bar.set_meta(&"_juice_danger_tw", tw)
		elif bar.has_meta(&"_juice_danger"):
			bar.remove_meta(&"_juice_danger")
			var tw: Tween = bar.get_meta(&"_juice_danger_tw")
			if tw:
				tw.kill()
			bar.remove_meta(&"_juice_danger_tw")
			bar.modulate = Color.WHITE


## Umbral cruzado (Player emite *_strike justo antes de que salga la monja).
func _on_strike(level: int, stat: StringName) -> void:
	var bar: ProgressBar = _bars.get(stat)
	if bar and is_instance_valid(bar):
		Juice.flash(bar, Color(1.8, 0.4, 0.35), 0.9)
	# El mundo pierde el color un instante y una onda recorre el mapa.
	var center: Vector2 = get_viewport().get_visible_rect().size * 0.5
	Juice.ripple(center, 1.5 + 0.5 * level, 1.1)
	Juice.grade_pulse(0.45 + 0.15 * level, 0.35, 1.6)
	match stat:
		&"rey":    # el Rey se enfada: temblor sutil + golpe
			Juice.shake(0.25 + 0.15 * level)
			Juice.sfx(&"thud", -2.0)
			Juice.vignette_flash(Color(0.45, 0.03, 0.02), 1.2, 0.5 + 0.15 * level)
		&"clero":  # la Iglesia: campana grave
			Juice.shake(0.1 + 0.08 * level)
			Juice.sfx(&"toll", -3.0)
			Juice.vignette_flash(Color(0.18, 0.08, 0.2), 1.4, 0.45 + 0.15 * level)
		&"nobleza":  # la Nobleza: portazo
			Juice.shake(0.12 + 0.1 * level)
			Juice.sfx(&"thud", -3.0, 1.15)
			Juice.vignette_flash(Color(0.12, 0.1, 0.25), 1.1, 0.45 + 0.15 * level)


# --- Descontento ---------------------------------------------------------------

## Capa de efectos del mundo dentro de la interfaz, justo antes de la monja y
## de las ventanas: las partículas de lacres, edificios y barras quedan por
## encima del HUD pero por debajo de cualquier ventana abierta.
func _build_world_fx() -> void:
	var monja: Node = main.get(&"monja_speak")
	var ui_layer: Node = monja.get_parent() if monja else null
	if ui_layer == null:
		return
	var host := Control.new()
	host.name = "JuiceWorldFx"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child.call_deferred(host)
	ui_layer.move_child.call_deferred(host, monja.get_index())
	Juice.register_world_fx(host)


func _build_vignette() -> void:
	# Postprocesado del mundo: bajo la interfaz (en el lienzo del mapa) para no
	# tocar textos ni barras. Incluye la viñeta del Descontento, las ondas de
	# tinta, la gradación de color y el grano.
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/fx/map_post.gdshader")
	_vignette.material = mat
	_vignette.name = "JuicePost"
	var size: Vector2 = get_viewport().get_visible_rect().size
	_vignette.position = Vector2(-40, -40)
	_vignette.size = size + Vector2(80, 80)
	_vignette.z_index = 50
	main.add_child.call_deferred(_vignette)
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	mat.set_shader_parameter(&"aspect", Vector2(vp_size.x / vp_size.y, 1.0))
	Juice.register_post(mat)
	_update_vignette(Player.descontento, true)
	Juice.settings_changed.connect(_on_settings_changed)


func _on_settings_changed() -> void:
	_update_vignette(_last.get(&"descontento", 0), true)


func _update_vignette(value: float, instant: bool = false) -> void:
	if _vignette == null:
		return
	var target := 0.0
	if Juice.enabled:
		target = clampf((value - DESCONTENTO_VIGNETTE_FROM) / (100.0 - DESCONTENTO_VIGNETTE_FROM), 0.0, 1.0)
	var mat := _vignette.material as ShaderMaterial
	mat.set_shader_parameter(&"pulse", 0.0 if Juice.reduce_motion else clampf(target * 1.5, 0.0, 1.0))
	# Con Descontento alto Madrid se apaga: menos color y algo de sepia.
	Juice.set_base_grade(target * 0.35, target * 0.25)
	if instant:
		_vignette_value = target
		mat.set_shader_parameter(&"intensity", target)
		return
	var tw := _vignette.create_tween()
	tw.tween_method(func(v: float):
		_vignette_value = v
		mat.set_shader_parameter(&"intensity", v), _vignette_value, target, 0.8)


# --- Riqueza y edificios ---------------------------------------------------------

func _on_riqueza(value: int) -> void:
	var old: int = _last.get(&"riqueza", value)
	_last[&"riqueza"] = value
	var delta := value - old
	_check_buildings()
	if delta == 0:
		return
	var label: Control = main.get(&"riqueza_label")
	var pos := Juice.screen_center(label) if label else Vector2(120, 40)
	if delta > 0:
		# Renta diaria: monedas y tintineo.
		Juice.burst(pos, &"coins", clampf(delta / 20.0, 0.5, 1.5))
		Juice.float_text(pos + Vector2(0, 34), "+%d" % delta, GOOD)
		Juice.sfx(&"coin", -4.0)
		if label:
			Juice.pop(label, 0.2)
	else:
		Juice.float_text(pos + Vector2(0, 34), "−%d" % -delta, BAD)
		Juice.sfx(&"coin", -2.0, 0.75)
		if label:
			Juice.flash(label, Color(1.6, 0.6, 0.5), 0.5)


## Compra y donación de edificios: BuildingManager no emite señales, así que se
## compara el dueño de cada edificio tras cada cambio de riqueza/influencia.
func _check_buildings() -> void:
	for building in BuildingManager.buildings:
		var before = _owners.get(building.id, building.owner)
		if before == building.owner:
			continue
		_owners[building.id] = building.owner
		var node := _building_node(building)
		var pos := Juice.screen_center(node) if node else Vector2.ZERO
		if building.owner == Building.Owner.PLAYER:
			# Comprado: sello de propiedad dorado.
			_after(0.05, func():
				if node:
					Juice.squash(node)
					Juice.burst(pos, &"gold")
					Juice.burst(pos, &"stamp", 0.7)
					Juice.ripple(pos, 1.0, 0.7)
				Juice.sfx(&"seal")
				Juice.sfx(&"chime", -8.0, 1.25))
			var window: Control = main.get(&"building_window")
			if window and window.visible and window.has_node(^"PanelContainer"):
				Juice.pop(window.get_node(^"PanelContainer"), 0.03, 0.3)
		elif building.owner == Building.Owner.FACTION:
			# Donado: campana y destello hacia la facción.
			_after(0.05, func():
				if node:
					Juice.pop(node, 0.2)
					Juice.burst(pos, &"glint", 1.5)
					Juice.burst(pos, &"dust")
				Juice.sfx(&"bell", -6.0, 1.2))


func _building_node(building) -> Node2D:
	var container: Node = main.get(&"buildings_container")
	if container == null:
		return null
	for child in container.get_children():
		if child.get(&"building") == building:
			return child
	return null


# --- Días ----------------------------------------------------------------------

func _on_new_day() -> void:
	var label: Control = main.get(&"time_label")
	if label:
		# Se pasa la página del calendario.
		label.self_modulate.a = 0.25
		var tw := label.create_tween()
		tw.tween_property(label, ^"self_modulate:a", 1.0, 0.45)
	if TimeManager.get_date_map().get("weekday", -1) == 0:
		# Los domingos suenan las campanas de Madrid, lejanas.
		Juice.sfx(&"bell", -16.0, 1.0, 0.0)


# --- Ventanas, agentes y monja --------------------------------------------------

func _on_window_visibility(window: Control, key: StringName) -> void:
	if not window.visible:
		if key == &"mission_window":
			_watch_mission(null)
		return
	var panel: CanvasItem = window.get_node_or_null(^"PanelContainer")
	Juice.window_in(panel if panel else window)
	# El lacre decorativo de la carta (rediseño de UI) se estampa al abrirla.
	var seal: CanvasItem = window.get_node_or_null(^"Lacre")
	if seal and key != &"mission_resolution_window":
		_after(0.08, func():
			Juice.drop_in(seal, 0.35)
			Juice.sfx(&"seal", -10.0, 1.1))
	match key:
		&"mission_window":
			_watch_mission(window.get(&"mission"))
		&"mission_resolution_window":
			_resolution_feedback(window, seal)


## Resultado: los efectos salen del lacre de la carta (esquina), no del texto,
## para no tapar el rótulo ni la descripción.
func _resolution_feedback(window: Control, seal: CanvasItem) -> void:
	var mission: Mission = window.get(&"mission")
	var outcome: Control = window.get(&"outcome_label")
	if mission == null:
		return
	_after(0.2, func():
		var pos: Vector2
		if seal:
			pos = Juice.screen_center(seal)
		elif outcome:
			pos = Juice.screen_center(outcome)
		else:
			pos = window.get_viewport_rect().size * 0.5
		if mission.success():
			# Éxito: el lacre se abre con destellos dorados y una campanilla.
			Juice.burst(pos, &"gold", 1.2, true)
			Juice.sfx(&"chime", -4.0)
			if seal:
				Juice.pop(seal, 0.2)
			if outcome:
				Juice.flash(outcome, Color(1.4, 1.3, 1.0), 0.6)
		else:
			# Fracaso: el lacre se quiebra y la tinta se derrama.
			Juice.burst(pos, &"wax", 1.0, true)
			Juice.burst(pos, &"ink", 0.8, true)
			Juice.sfx(&"crack", -3.0, 0.9)
			Juice.sfx(&"thud", -6.0)
			Juice.shake(0.15)
			Juice.grade_pulse(0.35, 0.2, 1.0)
			if seal:
				Juice.squash(seal))


## Huecos de agentes: se escucha agents_changed de la misión abierta.
func _watch_mission(mission: Mission) -> void:
	if _watched_mission and _watched_mission.agents_changed.is_connected(_on_agents_changed):
		_watched_mission.agents_changed.disconnect(_on_agents_changed)
	_watched_mission = mission
	_slot_agents.clear()
	if mission == null:
		return
	mission.agents_changed.connect(_on_agents_changed)
	_snapshot_slots.call_deferred(false)


func _on_agents_changed() -> void:
	# AgentSelector asigna slot.agent después de emitir la señal: diferir.
	_snapshot_slots.call_deferred(true)


func _snapshot_slots(feedback: bool) -> void:
	var window: Node = main.get(&"mission_window")
	var roast: Node = window.get(&"agent_roast") if window else null
	if roast == null:
		return
	for slot in roast.get_children():
		var agent = slot.get(&"agent")
		var before = _slot_agents.get(slot)
		if feedback and agent != before and is_instance_valid(slot):
			var pos := Juice.screen_center(slot)
			if agent != null:
				# Agente colocado: el retrato se asienta en el hueco.
				Juice.squash(slot, 0.35)
				Juice.burst(pos, &"dust", 0.8, true)
				Juice.sfx(&"seal", -8.0, 1.4)
			else:
				Juice.burst(pos, &"dust", 0.4, true)
				Juice.sfx(&"paper", -10.0, 1.3)
		_slot_agents[slot] = agent


func _on_monja_visibility(monja: Node) -> void:
	var label: CanvasItem = monja.get_node(^"Label")
	if not label.visible:
		return
	Juice.sfx(&"paper", -2.0, 0.85)
	var nun: CanvasItem = monja.get_node_or_null(^"TextureRect")
	var scroll: CanvasItem = monja.get_node_or_null(^"TextureRect2")
	if nun:
		Juice.fade_in(nun, 0.35, Vector2(-30, 0))
	if scroll:
		Juice.fade_in(scroll, 0.3)   # velo a pantalla completa: sin desplazar
	Juice.fade_in(label, 0.3, Vector2(0, 14))


# --- Utilidades ----------------------------------------------------------------

func _after(seconds: float, callback: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(func():
		if is_inside_tree():
			callback.call())
