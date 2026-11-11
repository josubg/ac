extends Node
## Ajustes del jugador: volumen por bus y pantalla completa.
## Se guardan en user://settings.cfg, sección [settings] (la misma que usa el idioma).
## Se aplican al arrancar. El idioma lo gestiona la localización (clave `locale`).

const PATH := "user://settings.cfg"
const SECTION := "settings"

## Bus de audio -> clave en el fichero
const BUSES := {
	"Master": "volume_master",
	"Musica": "volume_music",
	"Efectos": "volume_sfx",
}
const FULLSCREEN_KEY := "fullscreen"


func _ready() -> void:
	for bus in BUSES:
		_aplicar_volumen(bus, get_volume(bus))
	# En web, el navegador solo permite pantalla completa tras un gesto del jugador
	if not OS.has_feature("web") and is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(PATH) # si no existe, se crea al guardar
	return cfg


func _guardar(key: String, value: Variant) -> void:
	var cfg := _cfg()
	cfg.set_value(SECTION, key, value)
	var err := cfg.save(PATH)
	if err != OK:
		push_error("Ajustes: no se pudo guardar %s (%s)" % [key, error_string(err)])


## Volumen lineal 0..1 del bus
func get_volume(bus: String) -> float:
	return clampf(float(_cfg().get_value(SECTION, BUSES[bus], 1.0)), 0.0, 1.0)


func set_volume(bus: String, linear: float) -> void:
	_aplicar_volumen(bus, linear)
	_guardar(BUSES[bus], clampf(linear, 0.0, 1.0))


func is_fullscreen() -> bool:
	return bool(_cfg().get_value(SECTION, FULLSCREEN_KEY, false))


func set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_MAXIMIZED)
	_guardar(FULLSCREEN_KEY, enabled)


func _aplicar_volumen(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))
