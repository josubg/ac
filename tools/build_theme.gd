extends SceneTree
## Construye el tema global de Cuatro Cortes (assets/ui/theme/cuatro_cortes.tres).
## Es la fuente de verdad del tema: edita aquí y vuelve a ejecutar.
##
##   Godot --headless --path . --script res://tools/build_theme.gd
##
## Paleta y tipos documentados en docs/ui/DISENO.md

const OUT := "res://assets/ui/theme/cuatro_cortes.tres"
const FONTS := "res://assets/ui/theme/fonts/"
const TEX := "res://assets/ui/textures/"

# Paleta
const PERGAMINO := Color("e6d3a8")
const PERGAMINO_CLARO := Color("f1e4c4")
const TINTA := Color("2b1b12")
const TINTA_SUAVE := Color("5a4232")
const LACRE := Color("7e1a16")
const LACRE_VIVO := Color("9a2a22")
const ORO := Color("a8843a")
const ORO_CLARO := Color("c9a65a")
const NOGAL := Color("22160f")

var t := Theme.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(FONTS)
	_build()
	var err := ResourceSaver.save(t, OUT)
	print("build_theme: ", OUT, " -> ", error_string(err))
	quit(0 if err == OK else 1)


# ---------------------------------------------------------------- utilidades

func _font(file: String, name: String, weight := -1, spacing_glyph := 0, lining := false) -> Font:
	var base: FontFile = load(file)
	var fv := FontVariation.new()
	fv.base_font = base
	if lining:
		fv.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("lnum"): 1}
	if weight > 0:
		fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	if spacing_glyph != 0:
		fv.spacing_glyph = spacing_glyph
	var path := FONTS + name + ".tres"
	ResourceSaver.save(fv, path)
	return load(path)


func _tex_box(file: String, margin: float, content: Vector4, tile := false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(TEX + file)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return sb


func _flat(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 0, pad := Vector4(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	sb.anti_aliasing = true
	return sb


func _variation(name: String, base: String) -> void:
	t.add_type(name)
	t.set_type_variation(name, base)


# ---------------------------------------------------------------- tema

func _build() -> void:
	var garamond := _font("res://assets/ui/fonts/ebgaramond/EBGaramond-VF.ttf", "garamond_texto", 460)
	var garamond_negrita := _font("res://assets/ui/fonts/ebgaramond/EBGaramond-VF.ttf", "garamond_negrita", 640)
	var fell_versalitas := _font("res://assets/ui/fonts/imfellenglishsc/IMFeENsc28P.ttf", "fell_versalitas", -1, 1)
	var fell_cursiva := _font("res://assets/ui/fonts/imfellenglish/IMFeENit28P.ttf", "fell_cursiva")
	var fell_redonda := _font("res://assets/ui/fonts/imfellenglish/IMFeENrm28P.ttf", "fell_redonda")
	var cifras := _font("res://assets/ui/fonts/ebgaramond/EBGaramond-VF.ttf", "garamond_cifras", 600, 0, true)
	var fraktur := _font("res://assets/ui/fonts/unifrakturmaguntia/UnifrakturMaguntia-Book.ttf", "fraktur_titular")

	t.default_font = garamond
	t.default_font_size = 22

	# --- Texto
	t.set_color("font_color", "Label", TINTA)
	t.set_constant("line_spacing", "Label", 2)

	t.set_font("normal_font", "RichTextLabel", garamond)
	t.set_font("bold_font", "RichTextLabel", garamond_negrita)
	t.set_font("italics_font", "RichTextLabel", fell_cursiva)
	t.set_font("bold_italics_font", "RichTextLabel", fell_cursiva)
	for k in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		t.set_font_size(k, "RichTextLabel", 22)
	t.set_color("default_color", "RichTextLabel", TINTA)
	t.set_constant("line_separation", "RichTextLabel", 3)

	# Título de carta (ventanas de pergamino)
	_variation("TituloCarta", "Label")
	t.set_font("font", "TituloCarta", fell_versalitas)
	t.set_font_size("font_size", "TituloCarta", 40)
	t.set_color("font_color", "TituloCarta", TINTA)

	# Subtítulo / veredicto
	_variation("SubtituloCarta", "Label")
	t.set_font("font", "SubtituloCarta", fell_versalitas)
	t.set_font_size("font_size", "SubtituloCarta", 28)
	t.set_color("font_color", "SubtituloCarta", LACRE)

	# Nota a pie, en cursiva (indicaciones al jugador)
	_variation("NotaCarta", "Label")
	t.set_font("font", "NotaCarta", fell_cursiva)
	t.set_font_size("font_size", "NotaCarta", 20)
	t.set_color("font_color", "NotaCarta", TINTA_SUAVE)

	# Voz (la monja, los sonetos)
	_variation("Voz", "Label")
	t.set_font("font", "Voz", fell_cursiva)
	t.set_font_size("font_size", "Voz", 28)
	t.set_color("font_color", "Voz", TINTA)
	t.set_constant("line_spacing", "Voz", 4)

	# Etiquetas sobre cuero (HUD)
	_variation("EtiquetaCuero", "Label")
	t.set_font("font", "EtiquetaCuero", fell_versalitas)
	t.set_font_size("font_size", "EtiquetaCuero", 26)
	t.set_color("font_color", "EtiquetaCuero", PERGAMINO)
	t.set_color("font_shadow_color", "EtiquetaCuero", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_y", "EtiquetaCuero", 2)
	t.set_constant("shadow_offset_x", "EtiquetaCuero", 0)

	_variation("CifraCuero", "Label")
	t.set_font("font", "CifraCuero", fell_redonda)
	t.set_font_size("font_size", "CifraCuero", 34)
	t.set_color("font_color", "CifraCuero", ORO_CLARO)
	t.set_color("font_shadow_color", "CifraCuero", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_y", "CifraCuero", 2)

	_variation("NotaCuero", "Label")
	t.set_font("font", "NotaCuero", fell_cursiva)
	t.set_font_size("font_size", "NotaCuero", 21)
	t.set_color("font_color", "NotaCuero", Color(PERGAMINO, 0.75))

	# Fecha en la cartela
	_variation("Fecha", "Label")
	t.set_font("font", "Fecha", fell_redonda)
	t.set_font_size("font_size", "Fecha", 24)
	t.set_color("font_color", "Fecha", TINTA)

	# Pantallas de cierre
	_variation("Soneto", "Label")
	t.set_font("font", "Soneto", fell_cursiva)
	t.set_font_size("font_size", "Soneto", 50)
	t.set_color("font_color", "Soneto", PERGAMINO)
	t.set_color("font_shadow_color", "Soneto", Color(0, 0, 0, 0.7))
	t.set_constant("shadow_offset_y", "Soneto", 3)
	t.set_constant("line_spacing", "Soneto", 10)

	_variation("TitularFinal", "Label")
	t.set_font("font", "TitularFinal", fraktur)
	t.set_font_size("font_size", "TitularFinal", 160)
	t.set_color("font_color", "TitularFinal", ORO_CLARO)
	t.set_color("font_shadow_color", "TitularFinal", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_y", "TitularFinal", 5)

	# --- Paneles (por defecto, vacíos: el pergamino se pide explícitamente)
	t.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "Panel", StyleBoxEmpty.new())

	var carta := _tex_box("pergamino_carta.png", 64, Vector4(64, 56, 64, 52))
	_variation("PanelPergamino", "PanelContainer")
	t.set_stylebox("panel", "PanelPergamino", carta)

	var cartela := _tex_box("pergamino_cartela.png", 20, Vector4(22, 8, 22, 8))
	_variation("PanelCartela", "PanelContainer")
	t.set_stylebox("panel", "PanelCartela", cartela)
	_variation("PanelCartelaSimple", "Panel")
	t.set_stylebox("panel", "PanelCartelaSimple", cartela)

	var ficha := _tex_box("pergamino_ficha.png", 24, Vector4(18, 12, 18, 12))
	_variation("PanelFicha", "PanelContainer")
	t.set_stylebox("panel", "PanelFicha", ficha)

	var cuero_sup := _tex_box("cuero_superior.png", 0, Vector4(24, 4, 24, 12), true)
	cuero_sup.texture_margin_bottom = 10
	_variation("PanelCueroSuperior", "Panel")
	t.set_stylebox("panel", "PanelCueroSuperior", cuero_sup)

	var cuero_inf := _tex_box("cuero_inferior.png", 0, Vector4(16, 14, 16, 6), true)
	cuero_inf.texture_margin_top = 10
	_variation("PanelCueroInferior", "PanelContainer")
	t.set_stylebox("panel", "PanelCueroInferior", cuero_inf)

	# Ficha de agente al pasar el ratón
	_variation("PanelFichaAgente", "Panel")
	var fa := _flat(Color(NOGAL, 0.92), ORO, 0)
	fa.border_width_top = 2
	t.set_stylebox("panel", "PanelFichaAgente", fa)

	# --- Botones: lacre (acción principal)
	var lacre_n := _tex_box("boton_lacre.png", 14, Vector4(26, 8, 26, 10))
	var lacre_h := _tex_box("boton_lacre_hover.png", 14, Vector4(26, 8, 26, 10))
	var lacre_p := _tex_box("boton_lacre_pulsado.png", 14, Vector4(26, 10, 26, 8))
	var lacre_d := _tex_box("boton_lacre_inactivo.png", 14, Vector4(26, 8, 26, 10))
	var foco := _flat(Color(0, 0, 0, 0), ORO_CLARO, 2, 10)
	foco.expand_margin_left = 3
	foco.expand_margin_right = 3
	foco.expand_margin_top = 3
	foco.expand_margin_bottom = 3
	t.set_stylebox("normal", "Button", lacre_n)
	t.set_stylebox("hover", "Button", lacre_h)
	t.set_stylebox("pressed", "Button", lacre_p)
	t.set_stylebox("hover_pressed", "Button", lacre_p)
	t.set_stylebox("disabled", "Button", lacre_d)
	t.set_stylebox("focus", "Button", foco)
	t.set_font("font", "Button", fell_versalitas)
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Button", PERGAMINO_CLARO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", PERGAMINO)
	t.set_color("font_hover_pressed_color", "Button", PERGAMINO)
	t.set_color("font_focus_color", "Button", PERGAMINO_CLARO)
	t.set_color("font_disabled_color", "Button", Color(PERGAMINO_CLARO, 0.7))
	t.set_color("icon_normal_color", "Button", PERGAMINO_CLARO)
	t.set_color("icon_hover_color", "Button", Color.WHITE)
	t.set_color("icon_pressed_color", "Button", PERGAMINO)
	t.set_color("icon_disabled_color", "Button", Color(PERGAMINO_CLARO, 0.6))
	t.set_constant("h_separation", "Button", 10)
	t.set_constant("icon_max_width", "Button", 26)

	# Secundario: trazo de tinta sobre pergamino
	_variation("BotonTinta", "Button")
	var tinta_n := _flat(Color(TINTA, 0.0), Color(TINTA, 0.7), 1, 4, Vector4(16, 4, 16, 6))
	var tinta_h := _flat(Color(TINTA, 0.10), TINTA, 1, 4, Vector4(16, 4, 16, 6))
	var tinta_p := _flat(Color(TINTA, 0.18), TINTA, 1, 4, Vector4(16, 5, 16, 5))
	t.set_stylebox("normal", "BotonTinta", tinta_n)
	t.set_stylebox("hover", "BotonTinta", tinta_h)
	t.set_stylebox("pressed", "BotonTinta", tinta_p)
	t.set_stylebox("hover_pressed", "BotonTinta", tinta_p)
	t.set_stylebox("disabled", "BotonTinta", _flat(Color(0, 0, 0, 0), Color(TINTA, 0.25), 1, 4, Vector4(16, 4, 16, 6)))
	t.set_font_size("font_size", "BotonTinta", 22)
	t.set_color("font_color", "BotonTinta", TINTA)
	t.set_color("font_hover_color", "BotonTinta", LACRE)
	t.set_color("font_pressed_color", "BotonTinta", LACRE)
	t.set_color("font_hover_pressed_color", "BotonTinta", LACRE)
	t.set_color("font_focus_color", "BotonTinta", TINTA)
	t.set_color("font_disabled_color", "BotonTinta", Color(TINTA, 0.4))

	# Opción conmutable (selector de idioma): tinta en reposo, lacre al elegirla
	_variation("BotonOpcion", "Button")
	t.set_stylebox("normal", "BotonOpcion", tinta_n)
	t.set_stylebox("hover", "BotonOpcion", tinta_h)
	t.set_stylebox("pressed", "BotonOpcion", lacre_n)
	t.set_stylebox("hover_pressed", "BotonOpcion", lacre_h)
	t.set_font_size("font_size", "BotonOpcion", 26)
	t.set_color("font_color", "BotonOpcion", TINTA)
	t.set_color("font_hover_color", "BotonOpcion", LACRE)
	t.set_color("font_pressed_color", "BotonOpcion", PERGAMINO_CLARO)
	t.set_color("font_hover_pressed_color", "BotonOpcion", Color.WHITE)
	t.set_color("font_focus_color", "BotonOpcion", TINTA)

	# Sobre cuero: filete de oro
	_variation("BotonCuero", "Button")
	var cuero_n := _flat(Color(NOGAL, 0.0), Color(ORO, 0.8), 1, 4, Vector4(14, 3, 14, 5))
	var cuero_h := _flat(Color(ORO, 0.16), ORO_CLARO, 1, 4, Vector4(14, 3, 14, 5))
	var cuero_p := _flat(Color(ORO, 0.26), ORO_CLARO, 1, 4, Vector4(14, 4, 14, 4))
	t.set_stylebox("normal", "BotonCuero", cuero_n)
	t.set_stylebox("hover", "BotonCuero", cuero_h)
	t.set_stylebox("pressed", "BotonCuero", cuero_p)
	t.set_stylebox("hover_pressed", "BotonCuero", cuero_p)
	t.set_font_size("font_size", "BotonCuero", 22)
	t.set_color("font_color", "BotonCuero", PERGAMINO)
	t.set_color("font_hover_color", "BotonCuero", PERGAMINO_CLARO)
	t.set_color("icon_normal_color", "BotonCuero", ORO_CLARO)
	t.set_color("icon_hover_color", "BotonCuero", PERGAMINO_CLARO)
	t.set_constant("icon_max_width", "BotonCuero", 24)

	# Menú principal: rótulos sobre el plano oscurecido
	_variation("BotonMenu", "Button")
	var menu_n := _flat(Color(NOGAL, 0.72), Color(ORO, 0.55), 0, 2, Vector4(24, 6, 24, 10))
	menu_n.border_width_top = 1
	menu_n.border_width_bottom = 1
	var menu_h := lacre_h.duplicate()
	t.set_stylebox("normal", "BotonMenu", menu_n)
	t.set_stylebox("hover", "BotonMenu", menu_h)
	t.set_stylebox("pressed", "BotonMenu", lacre_p)
	t.set_stylebox("hover_pressed", "BotonMenu", lacre_p)
	t.set_font_size("font_size", "BotonMenu", 40)
	t.set_color("font_color", "BotonMenu", PERGAMINO)

	# --- Barras de influencia
	var barra_fondo := _flat(Color("140c07"), Color(ORO, 0.7), 1, 2)
	barra_fondo.shadow_color = Color(0, 0, 0, 0.5)
	barra_fondo.shadow_size = 2
	t.set_stylebox("background", "ProgressBar", barra_fondo)
	var barra_relleno := _flat(ORO, Color(0, 0, 0, 0), 0, 1)
	barra_relleno.expand_margin_top = -2
	barra_relleno.expand_margin_bottom = -2
	barra_relleno.expand_margin_left = -2
	barra_relleno.expand_margin_right = -2
	t.set_stylebox("fill", "ProgressBar", barra_relleno)
	t.set_font("font", "ProgressBar", cifras)
	t.set_font_size("font_size", "ProgressBar", 17)
	t.set_color("font_color", "ProgressBar", PERGAMINO_CLARO)
	t.set_color("font_outline_color", "ProgressBar", Color(NOGAL, 0.9))
	t.set_constant("outline_size", "ProgressBar", 4)

	# --- Separadores, scroll, tooltip
	var regla := StyleBoxLine.new()
	regla.color = Color(ORO, 0.85)
	regla.thickness = 1
	t.set_stylebox("separator", "HSeparator", regla)
	t.set_constant("separation", "HSeparator", 14)

	var rail := _flat(Color(TINTA, 0.10), Color(0, 0, 0, 0), 0, 3)
	rail.content_margin_left = 6
	rail.content_margin_right = 6
	t.set_stylebox("scroll", "VScrollBar", rail)
	t.set_stylebox("grabber", "VScrollBar", _flat(Color(TINTA, 0.45), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", _flat(Color(LACRE, 0.8), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", _flat(LACRE, Color(0, 0, 0, 0), 0, 3))

	t.set_stylebox("panel", "TooltipPanel", cartela)
	t.set_color("font_color", "TooltipLabel", TINTA)
	t.set_font("font", "TooltipLabel", garamond)
	t.set_font_size("font_size", "TooltipLabel", 20)
