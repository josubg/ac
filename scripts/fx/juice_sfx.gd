class_name JuiceSfx
extends RefCounted
## Sonidos de "juice": grabaciones CC0 en res://assets/vfx/sfx/<nombre>.ogg
## (autor, página y licencia de cada una en assets/vfx/CREDITS.md).
##
## Nombres: seal (sello de lacre), crack (el lacre se rompe), paper (pergamino),
## coin (monedas), click (botón), thud (golpe sordo), chime (campanilla de
## éxito), bell (campana de iglesia), toll (campana grave de aviso).
## Para cambiar un sonido basta con sustituir el fichero (.ogg, .wav o .mp3).

const SFX_DIR := "res://assets/vfx/sfx/"

static var _cache: Dictionary = {}


## Devuelve el stream del sonido `sound`, o null si no hay fichero.
static func get_stream(sound: StringName) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	var stream: AudioStream = null
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s.%s" % [SFX_DIR, sound, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null:
		push_warning("JuiceSfx: falta el sonido %s en %s" % [sound, SFX_DIR])
	_cache[sound] = stream
	return stream
