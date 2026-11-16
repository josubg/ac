class_name LocaleSettings
## Idioma del juego: se guarda en user://settings.cfg ([settings] locale="es"|"en").
## El selector de Opciones debe llamar a LocaleSettings.set_and_save(locale).

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"
const KEY := "locale"
const DEFAULT_LOCALE := "es"
const SUPPORTED := ["es", "en"]

## Aplica el idioma guardado (o español si no hay ninguno). Se llama al arrancar.
## Para pruebas: `Godot --path . -- --locale=en` fuerza un idioma sin guardarlo.
static func apply_saved() -> void:
	var locale := DEFAULT_LOCALE
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		locale = str(cfg.get_value(SECTION, KEY, DEFAULT_LOCALE))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--locale="):
			locale = arg.trim_prefix("--locale=")
	if locale not in SUPPORTED:
		locale = DEFAULT_LOCALE
	TranslationServer.set_locale(locale)

static func set_and_save(locale: String) -> void:
	if locale not in SUPPORTED:
		push_warning("LocaleSettings: idioma no soportado '%s'" % locale)
		return
	TranslationServer.set_locale(locale)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SECTION, KEY, locale)
	cfg.save(SETTINGS_PATH)


## Entero con separador de millares según el idioma: en «2,500»; es «2500» y «12.500»
## (en español los números de cuatro cifras no llevan separador).
static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var english := TranslationServer.get_locale().begins_with("en")
	if english or digits.length() > 4:
		var sep := "," if english else "."
		var i := digits.length() - 3
		while i > 0:
			digits = digits.insert(i, sep)
			i -= 3
	return ("-" if value < 0 else "") + digits
