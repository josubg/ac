extends Node
## Autoload "Juice": API reutilizable de feedback (game feel) para Cuatro Cortes.
##
## Todo el feedback pasa por aquí para que haya un único interruptor:
##   Juice.enabled        -> apaga todos los efectos visuales y sonoros de juice.
##   Juice.reduce_motion  -> sin temblores, sin escalados ni desplazamientos;
##                           los efectos se convierten en fundidos/colores.
## Ambos se guardan en user://juice.cfg. F10 alterna "reducir movimiento" en
## cualquier momento (y muestra un aviso). En la web, si el navegador declara
## prefers-reduced-motion, se activa por defecto la primera vez.
##
## API principal (todas aceptan nodos nulos o ya liberados sin fallar):
##   shake(intensity)                 temblor sutil del mapa (0..1)
##   pop(node, strength)              "pop" de escala con rebote
##   squash(node)                     squash & stretch (sello que golpea)
##   drop_in(node)                    aparición: cae desde más grande y se asienta
##   pulse_loop(node, on)             latido continuo (lacre a punto de caducar)
##   flash(node, color, time)         destello de color (self_modulate)
##   fade_in(node, time, offset)      fundido de entrada con desplazamiento opcional
##   burst(screen_pos, kind, amount)  ráfaga de partículas (ver JuiceParticles)
##   float_text(screen_pos, text, c)  número flotante (+5, −10)
##   sfx(name, volume_db, pitch)      sonido (ver JuiceSfx)
##   vignette_flash(color, time)      velo de color en los bordes de la pantalla
##   ripple(screen_pos, strength)     onda de tinta que deforma el mapa (postprocesado)
##   grade_pulse(desat, sepia, time)  el mapa pierde color un instante (postprocesado)
##   attach_main(main)                engancha el feedback de la partida (MainJuice)

signal settings_changed

const CONFIG_PATH := "user://juice.cfg"
const MainJuiceScript := preload("res://scripts/fx/main_juice.gd")

## Volumen global (dB) de los sonidos de juice.
var sfx_volume_db: float = -6.0

var enabled: bool = true:
	set(value):
		enabled = value
		_save_settings()
		settings_changed.emit()

var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if value:
			_trauma = 0.0
			_reset_canvas()
		_save_settings()
		settings_changed.emit()

var _fx_layer: CanvasLayer
var _overlay_layer: CanvasLayer
var _overlay: ColorRect
var _edge: ColorRect
var _toast: Label
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _trauma := 0.0
var _shake_time := 0.0
var _shaking := false
var _ambient: Node = null
var _loading := true
var _post: ShaderMaterial = null     # postprocesado del mapa (lo registra MainJuice)
var _ripples: Array = []             # [pos_uv, age, strength, duration]
var _grade := Vector2.ZERO           # desaturación/sepia transitorias
var _base_grade := Vector2.ZERO      # desaturación/sepia de fondo (Descontento)

## Bus de audio para los efectos (lo crea ui-redesign; si no existe, Master).
const SFX_BUS := &"Efectos"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_build_layers()
	var bus := SFX_BUS if AudioServer.get_bus_index(SFX_BUS) != -1 else &"Master"
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)
	_connect_game_manager.call_deferred()


func _connect_game_manager() -> void:
	var gm := get_node_or_null(^"/root/GameManager")
	if gm == null:
		return
	if gm.has_signal(&"scene_changed"):
		gm.scene_changed.connect(_on_scene_changed)
	if gm.has_signal(&"game_started"):
		gm.game_started.connect(_on_scene_changed.bind("Game"))


# --- Ajustes -------------------------------------------------------------------

## Movimiento permitido (enabled y sin "reducir movimiento").
func motion_enabled() -> bool:
	return enabled and not reduce_motion


func set_reduce_motion(value: bool) -> void:
	reduce_motion = value


func toggle_reduce_motion() -> void:
	reduce_motion = not reduce_motion
	toast(tr("Movimiento reducido: activado") if reduce_motion else tr("Movimiento reducido: desactivado"))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		enabled = cfg.get_value("juice", "enabled", true)
		reduce_motion = cfg.get_value("juice", "reduce_motion", false)
		sfx_volume_db = cfg.get_value("juice", "sfx_volume_db", sfx_volume_db)
	elif OS.has_feature("web"):
		var prefers = JavaScriptBridge.eval(
			"window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches", true)
		reduce_motion = prefers == true
	_loading = false


func _save_settings() -> void:
	if _loading:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("juice", "enabled", enabled)
	cfg.set_value("juice", "reduce_motion", reduce_motion)
	cfg.set_value("juice", "sfx_volume_db", sfx_volume_db)
	cfg.save(CONFIG_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		toggle_reduce_motion()
		get_viewport().set_input_as_handled()


# --- Capas propias ---------------------------------------------------------------

func _build_layers() -> void:
	_fx_layer = CanvasLayer.new()
	_fx_layer.name = "JuiceFx"
	_fx_layer.layer = 50
	add_child(_fx_layer)

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "JuiceOverlay"
	_overlay_layer.layer = 100
	add_child(_overlay_layer)

	_edge = ColorRect.new()
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.material = _make_vignette_material()
	_edge.visible = false
	_overlay_layer.add_child(_edge)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ShaderMaterial.new()
	ink.shader = load("res://scripts/fx/ink_transition.gdshader")
	ink.set_shader_parameter(&"progress", 0.0)
	_overlay.material = ink
	_overlay.visible = false
	_overlay_layer.add_child(_overlay)

	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(-300, 24)
	_toast.size = Vector2(600, 40)
	_toast.label_settings = _label_settings(26, Color(1, 0.95, 0.85))
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_toast)


func _make_vignette_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/fx/vignette.gdshader")
	mat.set_shader_parameter(&"intensity", 0.0)
	mat.set_shader_parameter(&"pulse", 0.0)
	return mat


## Crea un rectángulo de viñeta (mismo shader) para colocarlo en otra escena,
## p. ej. bajo la interfaz de la partida. Lo usa MainJuice para el Descontento.
func make_vignette_rect() -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _make_vignette_material()
	return rect


# --- Temblor ---------------------------------------------------------------------

## Temblor sutil del mundo (mapa y edificios); la interfaz no tiembla para que
## los textos sigan legibles. intensity 0..1 se acumula y decae solo.
func shake(intensity: float = 0.3) -> void:
	if not motion_enabled():
		return
	_trauma = clampf(_trauma + intensity, 0.0, 1.0)


func _process(delta: float) -> void:
	_process_post(delta)
	if _trauma > 0.0:
		_shaking = true
		_shake_time += delta
		_trauma = maxf(0.0, _trauma - delta * 1.4)
		var amount := _trauma * _trauma
		var vp := get_viewport()
		var size := vp.get_visible_rect().size
		var offset := Vector2(
			sin(_shake_time * 47.0) + 0.5 * sin(_shake_time * 91.0),
			cos(_shake_time * 53.0) + 0.5 * sin(_shake_time * 79.0)) * 9.0 * amount
		var rot := sin(_shake_time * 37.0) * 0.004 * amount
		var zoom := 1.0 + 0.012 * amount   # oculta los bordes del mapa
		var xf := Transform2D(rot, Vector2(zoom, zoom), 0.0, Vector2.ZERO)
		xf.origin = size * 0.5 - xf.basis_xform(size * 0.5) + offset
		vp.canvas_transform = xf
	elif _shaking:
		_reset_canvas()


# --- Postprocesado del mapa -----------------------------------------------------

## MainJuice registra aquí el material de map_post.gdshader.
func register_post(material: ShaderMaterial) -> void:
	_post = material
	_ripples.clear()
	_grade = Vector2.ZERO
	_base_grade = Vector2.ZERO
	_apply_post()


## Onda de tinta que se expande desde screen_pos (coordenadas de pantalla).
func ripple(screen_pos: Vector2, strength: float = 1.0, duration: float = 0.7) -> void:
	if _post == null or not motion_enabled():
		return
	var size := get_viewport().get_visible_rect().size
	if _ripples.size() >= 4:
		_ripples.pop_front()
	_ripples.append([screen_pos / size, 0.0, strength, duration])


## El mapa pierde color (desaturación) y vira a sepia, y se recupera en `time`.
func grade_pulse(desat: float = 0.6, sepia_amount: float = 0.4, time: float = 1.2) -> void:
	if _post == null or not enabled:
		return
	_grade = Vector2(maxf(_grade.x, desat), maxf(_grade.y, sepia_amount))
	var tw := create_tween()
	tw.tween_property(self, ^"_grade", Vector2.ZERO, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Gradación de fondo (persistente), p. ej. según el Descontento.
func set_base_grade(desat: float, sepia_amount: float) -> void:
	_base_grade = Vector2(desat, sepia_amount) if enabled else Vector2.ZERO


func _process_post(delta: float) -> void:
	if _post == null or not is_instance_valid(_post):
		return
	for r in _ripples:
		r[1] += delta / r[3]
	_ripples = _ripples.filter(func(r): return r[1] < 1.0)
	_apply_post()


func _apply_post() -> void:
	var data := PackedVector4Array()
	for i in 4:
		if i < _ripples.size():
			var r = _ripples[i]
			data.append(Vector4(r[0].x, r[0].y, r[1], r[2]))
		else:
			data.append(Vector4.ZERO)
	_post.set_shader_parameter(&"ripples", data)
	_post.set_shader_parameter(&"desaturate", clampf(_base_grade.x + _grade.x, 0.0, 1.0))
	_post.set_shader_parameter(&"sepia", clampf(_base_grade.y + _grade.y, 0.0, 1.0))
	_post.set_shader_parameter(&"grain_speed", 0.0 if reduce_motion else 1.0)
	_post.set_shader_parameter(&"grain", 0.03 if enabled else 0.0)


func _reset_canvas() -> void:
	_shaking = false
	if is_inside_tree():
		get_viewport().canvas_transform = Transform2D.IDENTITY


# --- Tweens sobre nodos --------------------------------------------------------

## Pop de escala con rebote. strength 0.15 = sube un 15 %.
func pop(node: CanvasItem, strength: float = 0.15, time: float = 0.35) -> void:
	if not _valid(node):
		return
	if not motion_enabled():
		flash(node, Color(1.35, 1.3, 1.15), time)
		return
	var tw := _scale_tween(node)
	tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE, Vector2.ONE * (1.0 + strength), time * 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE * (1.0 + strength), Vector2.ONE, time * 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.finished.connect(_restore_scale.bind(node))


## Squash & stretch: el objeto se aplasta como un sello y recupera su forma.
func squash(node: CanvasItem, time: float = 0.4) -> void:
	if not _valid(node):
		return
	if not motion_enabled():
		flash(node, Color(1.3, 1.25, 1.2), time)
		return
	var tw := _scale_tween(node)
	tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE, Vector2(1.25, 0.78), time * 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_rel_scale.bind(node), Vector2(1.25, 0.78), Vector2.ONE, time * 0.75) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.finished.connect(_restore_scale.bind(node))


## Aparición: el nodo cae desde más grande y transparente y se asienta.
func drop_in(node: CanvasItem, time: float = 0.45) -> void:
	if not _valid(node):
		return
	if not motion_enabled():
		fade_in(node, time * 0.6)
		return
	var tw := _scale_tween(node)
	_set_rel_scale(Vector2.ONE * 1.8, node)
	node.self_modulate.a = 0.0
	tw.set_parallel(true)
	tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE * 1.8, Vector2.ONE, time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, ^"self_modulate:a", 1.0, time * 0.5)
	tw.chain().tween_callback(_restore_scale.bind(node))


## Latido continuo (on = true) o lo detiene (on = false).
func pulse_loop(node: CanvasItem, on: bool, strength: float = 0.12, period: float = 0.9) -> void:
	if not _valid(node):
		return
	var old: Tween = node.get_meta(&"_juice_loop") if node.has_meta(&"_juice_loop") else null
	if old:
		old.kill()
		node.remove_meta(&"_juice_loop")
		_restore_scale(node)
	if not on or not enabled:
		return
	_capture_base(node)
	var tw := node.create_tween().set_loops()
	if motion_enabled():
		tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE, Vector2.ONE * (1.0 + strength), period * 0.18) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE * (1.0 + strength), Vector2.ONE, period * 0.32) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_interval(period * 0.5)
	else:
		tw.tween_property(node, ^"self_modulate", Color(1.4, 0.75, 0.7), period * 0.3)
		tw.tween_property(node, ^"self_modulate", Color.WHITE, period * 0.7)
	node.set_meta(&"_juice_loop", tw)


## Destello: tiñe el nodo (self_modulate, admite valores > 1) y vuelve al blanco.
func flash(node: CanvasItem, color: Color = Color(1.6, 1.4, 0.9), time: float = 0.4) -> void:
	if not _valid(node) or not enabled:
		return
	var key := &"_juice_flash"
	if node.has_meta(key):
		var old: Tween = node.get_meta(key)
		if old:
			old.kill()
	node.self_modulate = color
	var tw := node.create_tween()
	tw.tween_property(node, ^"self_modulate", Color.WHITE, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	node.set_meta(key, tw)


## Fundido de entrada. offset desplaza el nodo al principio (se ignora con
## movimiento reducido) y vuelve exactamente a su posición.
func fade_in(node: CanvasItem, time: float = 0.3, offset: Vector2 = Vector2.ZERO) -> void:
	if not _valid(node) or not enabled:
		return
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, ^"modulate:a", 1.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if offset != Vector2.ZERO and motion_enabled() and "position" in node:
		var target: Vector2 = node.position
		node.position = target + offset
		tw.tween_property(node, ^"position", target, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Entrada de ventana: fundido + leve escalado desde el centro.
func window_in(node: CanvasItem, time: float = 0.22) -> void:
	if not _valid(node) or not enabled:
		return
	node.modulate.a = 0.0
	var tw := _scale_tween(node).set_parallel(true)
	tw.tween_property(node, ^"modulate:a", 1.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if motion_enabled():
		_set_rel_scale(Vector2.ONE * 0.96, node)
		tw.tween_method(_set_rel_scale.bind(node), Vector2.ONE * 0.96, Vector2.ONE, time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(_restore_scale.bind(node))


# Escalar respecto al centro sin tocar pivot_offset en nodos escalados: si la
# escala base es 1 (botones en contenedores) basta con mover el pivote al
# centro; si no (el lacre está a 0.12), se compensa la posición y al final se
# restaura exactamente la posición y la escala originales.
func _capture_base(node: CanvasItem) -> void:
	if node.has_meta(&"_juice_base_scale"):
		return
	node.set_meta(&"_juice_base_scale", node.scale)
	node.set_meta(&"_juice_base_pos", node.position)


func _scale_tween(node: CanvasItem) -> Tween:
	if node.has_meta(&"_juice_tween"):
		var old: Tween = node.get_meta(&"_juice_tween")
		if old and old.is_valid():
			old.kill()
			_restore_scale(node)
	_capture_base(node)
	var tw := node.create_tween()
	node.set_meta(&"_juice_tween", tw)
	return tw


func _set_rel_scale(rel: Vector2, node: CanvasItem) -> void:
	if not is_instance_valid(node):
		return
	var base_scale: Vector2 = node.get_meta(&"_juice_base_scale", Vector2.ONE)
	if node is Control:
		var c := node as Control
		if base_scale == Vector2.ONE:
			c.pivot_offset = c.size * 0.5
			c.scale = rel
		else:
			var base_pos: Vector2 = node.get_meta(&"_juice_base_pos", c.position)
			c.scale = base_scale * rel
			c.position = base_pos + c.size * base_scale * (Vector2.ONE - rel) * 0.5
	elif node is Node2D:
		(node as Node2D).scale = base_scale * rel


func _restore_scale(node: CanvasItem) -> void:
	if not is_instance_valid(node) or not node.has_meta(&"_juice_base_scale"):
		return
	node.scale = node.get_meta(&"_juice_base_scale")
	if node is Control and node.get_meta(&"_juice_base_scale") != Vector2.ONE:
		node.position = node.get_meta(&"_juice_base_pos")
	node.remove_meta(&"_juice_base_scale")
	node.remove_meta(&"_juice_base_pos")


func _valid(node: Object) -> bool:
	return node != null and is_instance_valid(node) and (node as Node).is_inside_tree()


# --- Partículas, texto flotante, sonido -----------------------------------------

## Centro de un nodo en coordenadas de pantalla (sirve para Control y Node2D).
func screen_center(node: CanvasItem) -> Vector2:
	if not _valid(node):
		return Vector2.ZERO
	if node is Control:
		var c := node as Control
		var base_scale: Vector2 = c.get_meta(&"_juice_base_scale", c.scale)
		var base_pos: Vector2 = c.get_meta(&"_juice_base_pos", c.position)
		if c.has_meta(&"_juice_base_scale") and base_scale != Vector2.ONE:
			# En mitad de un tween compensado: usar la geometría de reposo.
			var parent_xf := c.get_global_transform_with_canvas() * c.get_transform().affine_inverse()
			return parent_xf * (base_pos + c.size * base_scale * 0.5)
		return c.get_global_transform_with_canvas() * (c.size * 0.5)
	return node.get_global_transform_with_canvas().origin


## Ráfaga de partículas en una posición de pantalla. kind: dust, wax, ink,
## gold, coins, glint, stamp. amount escala la densidad.
func burst(screen_pos: Vector2, kind: StringName, amount: float = 1.0) -> void:
	if not enabled:
		return
	var calm := 0.6 if reduce_motion else 1.0
	var p := JuiceParticles.make_burst(kind, amount * calm, calm)
	p.position = screen_pos
	_fx_layer.add_child(p)
	p.emitting = true
	var life: float = p.get_meta(&"juice_life", 2.0)
	get_tree().create_timer(life, true, false, true).timeout.connect(p.queue_free)


## Texto flotante (+5, −10…) que sube y se desvanece.
func float_text(screen_pos: Vector2, text: String, color: Color, size: int = 26) -> void:
	if not enabled:
		return
	var label := Label.new()
	label.text = text
	label.label_settings = _label_settings(size, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(label)
	label.reset_size()
	label.position = screen_pos - label.size * 0.5
	var tw := label.create_tween().set_parallel(true)
	if motion_enabled():
		tw.tween_property(label, ^"position:y", label.position.y - 46.0, 1.1) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, ^"modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(label.queue_free)


func _label_settings(size: int, color: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = maxi(4, size / 5)
	ls.outline_color = Color(0.12, 0.07, 0.04, 0.9)
	var font_path := "res://resources/AlbertText-Bold.ttf"
	if ResourceLoader.exists(font_path):
		ls.font = load(font_path)
	return ls


## Reproduce un sonido de JuiceSfx con una pequeña variación de tono.
func sfx(sound: StringName, volume_db: float = 0.0, pitch: float = 1.0, variation: float = 0.04) -> void:
	if not enabled:
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = JuiceSfx.get_stream(sound)
	player.volume_db = sfx_volume_db + volume_db
	player.pitch_scale = pitch * randf_range(1.0 - variation, 1.0 + variation)
	player.play()


## Velo de color en los bordes de toda la pantalla (aviso, ira del Rey…).
func vignette_flash(color: Color = Color(0.45, 0.02, 0.02), time: float = 0.9, strength: float = 0.8) -> void:
	if not enabled:
		return
	var mat := _edge.material as ShaderMaterial
	mat.set_shader_parameter(&"tint", color)
	_edge.visible = true
	var tw := _edge.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter(&"intensity", v), 0.0, strength, time * 0.2)
	tw.tween_method(func(v: float): mat.set_shader_parameter(&"intensity", v), strength, 0.0, time * 0.8)
	tw.tween_callback(func(): _edge.visible = false)


## Aviso breve en la parte superior.
func toast(text: String) -> void:
	_toast.text = text
	var tw := _toast.create_tween()
	tw.tween_property(_toast, ^"modulate:a", 1.0, 0.15)
	tw.tween_interval(1.4)
	tw.tween_property(_toast, ^"modulate:a", 0.0, 0.4)


# --- Transiciones de escena y ambiente -----------------------------------------

func _on_scene_changed(scene_name: String) -> void:
	_post = null
	_ripples.clear()
	_trauma = 0.0
	_reset_canvas()
	for child in _fx_layer.get_children():
		child.queue_free()
	if not enabled:
		return
	# Mancha de tinta que se retira desde el centro: suaviza el corte seco de
	# change_scene_to_file. Con movimiento reducido, más rápida.
	var ink := _overlay.material as ShaderMaterial
	ink.set_shader_parameter(&"seed", randf() * 100.0)
	ink.set_shader_parameter(&"progress", 1.0)
	_overlay.visible = true
	var time := 0.9 if scene_name != "GameOver" else 1.6
	if reduce_motion:
		time *= 0.6
	var tw := _overlay.create_tween()
	tw.tween_interval(0.08)
	tw.tween_method(func(v: float): ink.set_shader_parameter(&"progress", v), 1.0, 0.0, time) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func(): _overlay.visible = false)
	match scene_name:
		"GameOver":
			sfx(&"toll", -2.0, 0.9, 0.0)
			_start_ambient(&"ash", get_tree().current_scene)
		"GameEnd":
			sfx(&"chime", -4.0, 1.0, 0.0)
			_start_ambient(&"motes", get_tree().current_scene)
		_:
			_stop_ambient()


## Partículas ambientales detrás del texto de la escena final: se insertan en la
## propia escena justo después de su fondo (primer ColorRect/TextureRect).
func _start_ambient(kind: StringName, old_scene: Node) -> void:
	_stop_ambient()
	# La señal llega antes del cambio (change_scene_to_file es diferido):
	# esperar a que la escena nueva sea la actual.
	var scene: Node = null
	for i in 30:
		await get_tree().process_frame
		scene = get_tree().current_scene
		if scene != null and scene != old_scene:
			break
	if scene == null or scene == old_scene:
		return
	var rect := get_viewport().get_visible_rect()
	var p := JuiceParticles.make_ambient(kind, rect, 0.5 if reduce_motion else 1.0)
	p.emitting = true
	var holder := Node2D.new()
	holder.name = "JuiceAmbient"
	holder.add_child(p)
	scene.add_child(holder)
	var index := 0
	for child in scene.get_children():
		if child is ColorRect or child is TextureRect:
			index = child.get_index() + 1
			break
	scene.move_child(holder, index)
	_ambient = holder


func _stop_ambient() -> void:
	if _ambient and is_instance_valid(_ambient):
		_ambient.queue_free()
	_ambient = null


# --- Botones: hover y pulsación para todos los BaseButton --------------------------

func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta(&"juice_ignore"):
		var b := node as BaseButton
		b.mouse_entered.connect(_on_button_hover.bind(b, true))
		b.mouse_exited.connect(_on_button_hover.bind(b, false))
		b.button_down.connect(_on_button_down.bind(b))


func _on_button_hover(button: BaseButton, inside: bool) -> void:
	if not _valid(button) or button.disabled or button.has_meta(&"_juice_loop"):
		return
	if not motion_enabled():
		if enabled:
			button.self_modulate = Color(1.12, 1.08, 1.0) if inside else Color.WHITE
		return
	var tw := _scale_tween(button)
	var target := Vector2.ONE * (1.05 if inside else 1.0)
	var from: Vector2 = button.get_meta(&"_juice_hover_rel", Vector2.ONE)
	tw.tween_method(_set_rel_scale.bind(button), from, target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta(&"_juice_hover_rel", target)
	if not inside:
		tw.tween_callback(_restore_scale.bind(button))
		tw.tween_callback(button.remove_meta.bind(&"_juice_hover_rel"))


func _on_button_down(button: BaseButton) -> void:
	if not _valid(button):
		return
	sfx(&"click", -4.0, 1.0, 0.08)
	if not motion_enabled() or button.has_meta(&"_juice_loop"):
		return
	var tw := _scale_tween(button)
	var from: Vector2 = button.get_meta(&"_juice_hover_rel", Vector2.ONE)
	tw.tween_method(_set_rel_scale.bind(button), from, Vector2.ONE * 0.94, 0.06)
	tw.tween_method(_set_rel_scale.bind(button), Vector2.ONE * 0.94, from, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Partida -------------------------------------------------------------------

## Engancha el feedback de la partida a la escena principal. Una línea en
## main.gd (_ready). Devuelve el nodo MainJuice creado (hijo de main).
func attach_main(main: Node) -> Node:
	var mj: Node = MainJuiceScript.new()
	mj.name = "MainJuice"
	main.add_child(mj)
	mj.setup(main)
	return mj
