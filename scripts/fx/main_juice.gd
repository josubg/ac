extends Node
## Feedback de la partida. Lo crea Juice.attach_main(main) desde main.gd y vive
## como hijo de la escena principal (se libera con ella).
##
## No modifica la lógica: solo escucha señales que ya existen (Player,
## MissionManager, visibility_changed de las ventanas, agents_changed de la
## misión) y lee las variables @onready de main.gd por nombre. Si la escena
## cambia y alguna referencia desaparece, ese efecto simplemente no se dispara.

const GOOD := Color(1.0, 0.85, 0.45)       # dorado: favorable
const BAD := Color(1.0, 0.5, 0.45)         # carmesí claro: legible sobre marrón
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
var _vignette_tw: Tween
var _pending_deltas := {}        # stat -> [delta acumulado, pasivo]
var _pending_strikes := []       # [nivel, stat] del mismo frame
var _was_paused := false
var _monja_hidden_frame := -10


## true durante el cambio de día: TimeManager (autoload) procesa antes que
## MainJuice, así que si last_day ya cambió y nosotros aún no, el cambio que
## llega es pasivo (renta, influencia diaria, +1 de Descontento).
func _is_passive() -> bool:
	return TimeManager.last_day != _last_day and _last_day != -1


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
	Player.descontento_updated.connect(_on_stat.bind(&"descontento"))
	Player.riqueza_updated.connect(_on_riqueza)
	Player.rey_strike.connect(_on_strike.bind(&"rey"))
	Player.noble_strike.connect(_on_strike.bind(&"nobleza"))
	Player.iglesia_strike.connect(_on_strike.bind(&"clero"))
	MissionManager.added_mission.connect(_on_mission_added)
	MissionManager.warning_mission.connect(_on_mission_updated)
	MissionManager.closed_mission.connect(_on_mission_closed)

	# Ventanas (aparecen con show()/hide()).
	for key in [&"mission_window", &"mission_resolution_window", &"building_window", &"properties_window"]:
		var window: CanvasItem = main.get(key)
		if window:
			window.visibility_changed.connect(_on_window_visibility.bind(window, key))

	# Mensaje de la monja: monja_speak.mensaje() hace show() del Label.
	var monja: Node = main.get(&"monja_speak")
	if monja and monja.has_node(^"Label"):
		monja.get_node(^"Label").visibility_changed.connect(_on_monja_visibility.bind(monja))

	# Menú de pausa (Esc): todo el juice se congela mientras está abierto.
	var pause_menu: CanvasLayer = main.get_node_or_null(^"PauseMenu")
	if pause_menu:
		pause_menu.visibility_changed.connect(func(): Juice.set_frozen(pause_menu.visible))

	_build_vignette()
	_build_world_fx()
	_update_danger(true)


func _exit_tree() -> void:
	Juice.set_frozen(false)
	# Las señales de autoloads sobreviven a la escena: desconectar.
	for pair in [
		[Player.rey_updated, _on_stat], [Player.nobleza_updated, _on_stat],
		[Player.clero_updated, _on_stat], [Player.descontento_updated, _on_stat],
		[Player.riqueza_updated, _on_riqueza], [Player.rey_strike, _on_strike],
		[Player.noble_strike, _on_strike], [Player.iglesia_strike, _on_strike],
		[MissionManager.added_mission, _on_mission_added],
		[MissionManager.warning_mission, _on_mission_updated],
		[MissionManager.closed_mission, _on_mission_closed],
	]:
		var sig: Signal = pair[0]
		for c in sig.get_connections():
			if c.callable.get_object() == self:
				sig.disconnect(c.callable)


func _process(_delta: float) -> void:
	# Pausa (ventanas, monja): los bucles de aviso se detienen para no latir
	# junto al texto que se está leyendo.
	if TimeManager.paused != _was_paused:
		_was_paused = TimeManager.paused
		_set_loops_paused(_was_paused)
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
	button.set_meta(&"juice_silent", true)   # la ventana ya suena al abrirse
	Juice.drop_in(button)
	_after(0.18, func():
		var p: Vector2 = _button_pos.get(mission, Vector2.ZERO)
		Juice.burst(p, &"dust")
		Juice.ripple(p, 0.6, 0.6)
		Juice.sfx(&"seal", -4.0))


func _on_mission_updated(mission: Mission) -> void:
	var button := _button_for(mission)
	if button == null:
		return
	_button_pos[mission] = Juice.screen_center(button)
	var pos: Vector2 = _button_pos[mission]
	match mission.status:
		Mission.MISSION_STATUS.warning:
			# A punto de caducar: late como un corazón; un roce de papel avisa.
			_apply_lacre_state(button, mission)
			Juice.sfx(&"paper", -6.0, 0.8)
		Mission.MISSION_STATUS.on_course:
			# Enviada: el sello golpea el papel y deja un anillo de tinta.
			Juice.pulse_loop(button, false)
			_apply_lacre_state(button, mission)
			Juice.squash(button)
			Juice.burst(pos, &"stamp")
			Juice.ripple(pos, 1.0, 0.7)
			Juice.sfx(&"seal", 0.0, 0.9)
		Mission.MISSION_STATUS.succeded, Mission.MISSION_STATUS.failed:
			# Resuelta: brilla de vez en cuando para invitar a abrirla.
			_apply_lacre_state(button, mission)
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
		Juice.sfx(&"crack", 0.0)
		Juice.shake(0.18)
		Juice.grade_pulse(0.25, 0.1, 0.8)


## Con "reducir movimiento" el parpadeo del lacre (AnimationPlayer "blink" de
## MissionButton, alfa 1→0 a 2 Hz) se sustituye por un tinte fijo; sin él,
## se deja la animación original. No se toca la escena ni su script.
func _apply_lacre_state(button: MissionButton, mission: Mission) -> void:
	var anim: AnimationPlayer = button.get_node_or_null(^"AnimationPlayer")
	var calm := Juice.reduce_motion or not Juice.enabled
	match mission.status:
		Mission.MISSION_STATUS.warning:
			Juice.pulse_loop(button, true)
			if anim and calm:
				anim.stop()
				button.modulate = Color.WHITE
				button.self_modulate = Color(1.35, 0.8, 0.75) if Juice.enabled else Color.WHITE
			elif anim and not anim.is_playing():
				button.self_modulate = Color.WHITE
				anim.play(&"blink")
		Mission.MISSION_STATUS.on_course:
			if anim and calm:
				anim.stop()
				button.modulate = Color(1, 1, 1, 0.8)
			elif anim and not anim.is_playing():
				anim.play(&"blink")
				anim.speed_scale = 0.5
		_:
			Juice.pulse_loop(button, false)
			button.self_modulate = Color.WHITE
			button.modulate = Color.WHITE


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
	if stat == &"descontento":
		_update_vignette(value)
	_update_danger()
	_queue_delta(stat, delta)


## Agrupa los cambios de un mismo frame (varias facciones/edificios a la vez)
## en un solo efecto por barra.
func _queue_delta(stat: StringName, delta: int) -> void:
	if _pending_deltas.is_empty():
		_flush_deltas.call_deferred()
	var entry: Array = _pending_deltas.get(stat, [0, _is_passive()])
	entry[0] += delta
	_pending_deltas[stat] = entry


func _flush_deltas() -> void:
	var deltas := _pending_deltas
	_pending_deltas = {}
	if not is_inside_tree():   # la escena ya se cerró (derrota, menú)
		return
	for stat in deltas:
		var delta: int = deltas[stat][0]
		var passive: bool = deltas[stat][1]
		if delta == 0:
			continue
		if stat == &"riqueza":
			_riqueza_feedback(delta, passive)
			continue
		var bar: ProgressBar = _bars.get(stat)
		if bar == null or not is_instance_valid(bar):
			continue
		var good := delta < 0 if stat == &"descontento" else delta > 0
		var color := GOOD if good else BAD
		var text := ("+%d" if delta > 0 else "–%d") % absi(delta)
		if passive:
			# Cambio diario: solo un número pequeño y discreto, sin destello.
			if absi(delta) >= 2:
				Juice.float_text(_text_pos(bar), text, Color(color, 0.8), 18, false, -8.0)
			continue
		Juice.flash(bar, Color(1.5, 1.35, 0.9) if good else Color(1.6, 0.6, 0.55), 0.5)
		Juice.float_text(_text_pos(bar), text, color, 26, false, -10.0)
		if absi(delta) >= 10:
			Juice.pop(bar, 0.06, 0.3)


## Posición del número flotante: sobre la propia barra, en el extremo del
## relleno, apartándose del porcentaje centrado. Nunca sale de la barra ni tapa
## el rótulo de la fila (antes se salía por el borde derecho de la pantalla).
func _text_pos(bar: ProgressBar) -> Vector2:
	var c := Juice.screen_center(bar)
	var half := bar.size.x * 0.5
	var ratio := 0.0
	if bar.max_value > bar.min_value:
		ratio = (bar.value - bar.min_value) / (bar.max_value - bar.min_value)
	var x := c.x - half + bar.size.x * ratio
	var keep_out := 60.0   # el "45 %" va centrado en la barra
	if absf(x - c.x) < keep_out:
		x = c.x + keep_out + 20.0 if ratio >= 0.5 else c.x - keep_out - 20.0
	return Vector2(clampf(x, c.x - half + 24.0, c.x + half - 24.0), c.y)


## Barra en zona de peligro (< 20, el segundo aviso): late en rojo.
func _update_danger(force: bool = false) -> void:
	for stat in [&"rey", &"nobleza", &"clero"]:
		var bar: ProgressBar = _bars.get(stat)
		if bar == null or not is_instance_valid(bar):
			continue
		var danger: bool = _last[stat] < DANGER_THRESHOLD and Juice.enabled
		if danger == bar.has_meta(&"_juice_danger") and not force:
			continue
		if bar.has_meta(&"_juice_danger_tw"):
			var old: Tween = bar.get_meta(&"_juice_danger_tw")
			if old:
				old.kill()
			bar.remove_meta(&"_juice_danger_tw")
		if danger:
			bar.set_meta(&"_juice_danger", true)
			if Juice.reduce_motion:
				# Sin latido: tinte fijo.
				bar.modulate = Color(1.3, 0.75, 0.7)
			else:
				var tw := bar.create_tween().set_loops()
				tw.tween_property(bar, ^"modulate", Color(1.35, 0.7, 0.65), 0.5)
				tw.tween_property(bar, ^"modulate", Color.WHITE, 0.7)
				bar.set_meta(&"_juice_danger_tw", tw)
				if TimeManager.paused:
					tw.pause()
		elif bar.has_meta(&"_juice_danger"):
			bar.remove_meta(&"_juice_danger")
			var tw: Tween = bar.get_meta(&"_juice_danger_tw")
			if tw:
				tw.kill()
			bar.remove_meta(&"_juice_danger_tw")
			bar.modulate = Color.WHITE


## Umbral cruzado (Player emite *_strike justo antes de que salga la monja).
func _on_strike(level: int, stat: StringName) -> void:
	# Un mismo suceso puede cruzar varios umbrales en el mismo frame: se agrupan
	# y solo suena/tiembla el más grave (los destellos de barra sí, todos).
	var bar: ProgressBar = _bars.get(stat)
	if bar and is_instance_valid(bar):
		Juice.flash(bar, Color(1.8, 0.4, 0.35), 0.9)
	if _pending_strikes.is_empty():
		_flush_strikes.call_deferred()
	_pending_strikes.append([level, stat])


func _flush_strikes() -> void:
	var worst: Array = []
	if not is_inside_tree():   # la escena ya se cerró (derrota, menú)
		_pending_strikes.clear()
		return
	var priority := {&"rey": 3, &"clero": 2, &"nobleza": 1}
	for s in _pending_strikes:
		if worst.is_empty() or s[0] > worst[0] or (s[0] == worst[0] and priority[s[1]] > priority[worst[1]]):
			worst = s
	_pending_strikes.clear()
	if not worst.is_empty():
		_strike_feedback(worst[0], worst[1])


func _strike_feedback(level: int, stat: StringName) -> void:
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
			Juice.sfx(&"thud", 0.0)
			Juice.vignette_flash(Color(0.45, 0.03, 0.02), 1.2, 0.5 + 0.15 * level)
		&"clero":  # la Iglesia: campana grave
			Juice.shake(0.1 + 0.08 * level)
			Juice.sfx(&"toll", 0.0)
			Juice.vignette_flash(Color(0.18, 0.08, 0.2), 1.4, 0.45 + 0.15 * level)
		&"nobleza":  # la Nobleza: portazo
			Juice.shake(0.12 + 0.1 * level)
			Juice.sfx(&"thud", -1.0, 1.15)
			Juice.vignette_flash(Color(0.12, 0.1, 0.25), 1.1, 0.45 + 0.15 * level)


# --- Descontento ---------------------------------------------------------------

## Dos capas dentro de la interfaz:
## - JuiceWorldFx, antes de todo el HUD: las partículas del mapa (lacres,
##   edificios, monedas) nunca pasan por encima de rótulos, cifras o barras;
## - JuiceHudText, justo antes de la monja y las ventanas: los números que
##   flotan sobre las barras se ven sobre el HUD pero quedan bajo cualquier
##   ventana o mensaje abierto.
func _build_world_fx() -> void:
	var monja: Node = main.get(&"monja_speak")
	var ui_layer: Node = monja.get_parent() if monja else null
	if ui_layer == null:
		return
	var first_hud: Node = ui_layer.get_node_or_null(^"FondoSuperior")
	if first_hud == null:
		first_hud = ui_layer.get_node_or_null(^"HUD")
	var world := _fx_host("JuiceWorldFx")
	var text := _fx_host("JuiceHudText")
	ui_layer.add_child.call_deferred(world)
	ui_layer.move_child.call_deferred(world, first_hud.get_index() if first_hud else 0)
	ui_layer.add_child.call_deferred(text)
	ui_layer.move_child.call_deferred(text, monja.get_index() + 1)
	Juice.register_world_fx(world, text)


func _fx_host(host_name: String) -> Control:
	var host := Control.new()
	host.name = host_name
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return host


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
	_update_danger(true)
	# Relanzar los avisos de lacres en el modo nuevo.
	for mission in _button_pos.keys():
		var button := _button_for(mission)
		if button:
			_apply_lacre_state(button, mission)


func _set_loops_paused(paused: bool) -> void:
	var tweens: Array = []
	for stat in _bars:
		var bar: ProgressBar = _bars[stat]
		if bar and is_instance_valid(bar) and bar.has_meta(&"_juice_danger_tw"):
			tweens.append(bar.get_meta(&"_juice_danger_tw"))
	for button in main.get(&"buttons"):
		if is_instance_valid(button) and button.has_meta(&"_juice_loop"):
			tweens.append(button.get_meta(&"_juice_loop"))
	for tw in tweens:
		if tw and tw.is_valid():
			if paused:
				tw.pause()
			else:
				tw.play()


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
	if _vignette_tw and _vignette_tw.is_valid():
		_vignette_tw.kill()
	var tw := _vignette.create_tween()
	_vignette_tw = tw
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
	_queue_delta(&"riqueza", delta)


func _riqueza_feedback(delta: int, passive: bool) -> void:
	var label: Control = main.get(&"riqueza_label")
	var pos := Juice.screen_center(label) if label else Vector2(120, 40)
	# Todo por debajo de la franja superior: ni las monedas ni la cifra flotante
	# pasan por encima del contador o de los rótulos de la barra.
	var bar_bottom := pos.y + 30.0
	var top_bar: Control = main.get_node_or_null(^"CanvasLayerMission/HUD/TopBar")
	if top_bar:
		bar_bottom = top_bar.get_global_rect().end.y
	var text_pos := Vector2(pos.x, bar_bottom + 22.0)
	if passive:
		# Renta diaria: solo el número, pequeño y sin sonido (pasa cada 10 s).
		Juice.float_text(text_pos, ("+%d" if delta > 0 else "–%d") % absi(delta), Color(GOOD if delta > 0 else BAD, 0.8), 18, false, 16.0)
		return
	if delta > 0:
		# Ingreso extraordinario: monedas que saltan bajo la franja y caen al mapa.
		Juice.burst(Vector2(pos.x, bar_bottom + 70.0), &"coins", clampf(delta / 200.0, 0.5, 1.5))
		Juice.float_text(text_pos, "+%d" % delta, GOOD, 26, false, 24.0)
		Juice.sfx(&"coin", -4.0)
		if label:
			Juice.pop(label, 0.2)
	else:
		Juice.float_text(text_pos, "–%d" % -delta, BAD, 26, false, 24.0)
		Juice.sfx(&"coin", -5.0, 0.75)
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
		Juice.sfx(&"bell", -12.0, 1.0, 0.0)


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
	var panel: CanvasItem = window.get_node_or_null(^"PanelContainer")
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
			_burst_in(panel, pos, &"gold", 1.2)
			Juice.sfx(&"chime", -2.0)
			if seal:
				Juice.pop(seal, 0.2)
			if outcome:
				Juice.flash(outcome, Color(1.4, 1.3, 1.0), 0.6)
		else:
			# Fracaso: el lacre se quiebra y la tinta se derrama.
			_burst_in(panel, pos, &"wax", 1.0)
			_burst_in(panel, pos, &"ink", 0.8)
			Juice.sfx(&"crack", -1.0, 0.9)
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
	var roast: Node = window.get(&"agent_roster") if window else null
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
				_burst_in(window.get_node_or_null(^"PanelContainer"), pos, &"dust", 0.8)
				Juice.sfx(&"seal", -8.0, 1.4)
			else:
				_burst_in(window.get_node_or_null(^"PanelContainer"), pos, &"dust", 0.4)
				Juice.sfx(&"paper", -10.0, 1.3)
		_slot_agents[slot] = agent


func _on_monja_visibility(monja: Node) -> void:
	var label: CanvasItem = monja.get_node(^"Label")
	if not label.visible:
		_monja_hidden_frame = Engine.get_process_frames()
		return
	Juice.sfx(&"paper", -4.0, 0.85)
	# Mensajes en cola (main.gd): se cierra uno y se abre el siguiente en el
	# mismo frame. Entonces solo cambia el texto; el velo y la monja se quedan.
	var chained := Engine.get_process_frames() - _monja_hidden_frame <= 1
	var nun: CanvasItem = monja.get_node_or_null(^"TextureRect")
	var scroll: CanvasItem = monja.get_node_or_null(^"TextureRect2")
	if nun and not chained:
		Juice.fade_in(nun, 0.35, Vector2(-30, 0))
	if scroll and not chained:
		Juice.fade_in(scroll, 0.3)   # velo a pantalla completa: sin desplazar
	Juice.fade_in(label, 0.3, Vector2(0, 14))


# --- Utilidades ----------------------------------------------------------------

## Efecto que sale de una ventana: bajo su texto si hay panel; si no, en la
## capa del mundo (que la ventana tapa). Nunca por encima de lo que se lee.
func _burst_in(panel: CanvasItem, pos: Vector2, kind: StringName, amount: float) -> void:
	if panel:
		Juice.burst_under(panel, pos, kind, amount)
	else:
		Juice.burst(pos, kind, amount)

func _after(seconds: float, callback: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(func():
		if is_inside_tree():
			callback.call())
