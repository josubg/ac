class_name JuiceSfx
extends RefCounted
## Sonidos de "juice" sintetizados por código (sin ficheros externos).
##
## Todo se genera una sola vez, la primera vez que se pide, como AudioStreamWAV
## mono de 16 bits a 22 050 Hz: pesa poco en la build web y no arrastra
## licencias de terceros. Si más adelante se quieren sonidos grabados, basta con
## poner un .ogg/.wav con el mismo nombre en res://assets/vfx/sfx/ (ver get_stream).

const MIX_RATE := 22050
const SFX_DIR := "res://assets/vfx/sfx/"

static var _cache: Dictionary = {}
static var _rng := RandomNumberGenerator.new()


## Devuelve el stream del sonido `name`. Primero busca un fichero en SFX_DIR
## (para poder sustituir la síntesis por una grabación sin tocar código).
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
		_rng.seed = hash(sound)
		stream = _synth(sound)
	_cache[sound] = stream
	return stream


static func _synth(sound: StringName) -> AudioStream:
	match sound:
		&"seal":   # golpe sordo de un sello de lacre sobre el papel
			return _to_wav(_seal())
		&"crack":  # el lacre se resquebraja
			return _to_wav(_crack())
		&"paper":  # roce de pergamino
			return _to_wav(_paper(0.32))
		&"coin":   # dos monedas que tintinean
			return _to_wav(_coins())
		&"click":  # clic de botón, casi inaudible
			return _to_wav(_click())
		&"thud":   # golpe grave (fracaso, la Nobleza da un portazo)
			return _to_wav(_thud())
		&"chime":  # campanilla clara (éxito)
			return _to_wav(_bell(523.25, 1.6, 0.55))
		&"bell":   # campana de iglesia lejana (domingos, donaciones)
			return _to_wav(_bell(196.0, 2.6, 0.45))
		&"toll":   # campana grave de aviso (umbrales, derrota)
			return _to_wav(_bell(98.0, 3.4, 0.6))
	push_warning("JuiceSfx: sonido desconocido %s" % sound)
	return _to_wav(PackedFloat32Array([0.0]))


# --- Síntesis -----------------------------------------------------------------

static func _buffer(seconds: float) -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(int(seconds * MIX_RATE))
	return data


## Campana: parciales inarmónicos típicos de campana (hum, prima, tercera menor,
## quinta, octava…) con caídas exponenciales distintas.
static func _bell(freq: float, seconds: float, gain: float) -> PackedFloat32Array:
	var partials := [
		[0.5, 0.9, 1.0], [1.0, 1.0, 0.8], [1.19, 0.55, 0.6], [1.5, 0.4, 0.5],
		[2.0, 0.35, 0.4], [2.52, 0.25, 0.3], [3.0, 0.18, 0.22], [4.07, 0.12, 0.14],
	]
	var data := _buffer(seconds)
	for i in data.size():
		var t := float(i) / MIX_RATE
		var s := 0.0
		for p in partials:
			var decay: float = seconds * p[2] * 0.35
			s += p[1] * sin(TAU * freq * p[0] * t) * exp(-t / decay)
		var attack := minf(1.0, t / 0.004)
		data[i] = s * attack
	return _normalize(data, gain)


static func _seal() -> PackedFloat32Array:
	var data := _buffer(0.22)
	var phase := 0.0
	for i in data.size():
		var t := float(i) / MIX_RATE
		var f := 60.0 + 90.0 * exp(-t / 0.03)
		phase += TAU * f / MIX_RATE
		var body := sin(phase) * exp(-t / 0.06)
		var click := _rng.randf_range(-1, 1) * exp(-t / 0.006) * 0.5
		data[i] = body + click
	return _normalize(data, 0.7)


static func _crack() -> PackedFloat32Array:
	var data := _buffer(0.34)
	var starts := []
	for k in 7:
		starts.append(_rng.randf_range(0.0, 0.24))
	starts.sort()
	var prev := 0.0
	for i in data.size():
		var t := float(i) / MIX_RATE
		var s := 0.0
		for st in starts:
			var dt: float = t - st
			if dt >= 0.0 and dt < 0.03:
				s += _rng.randf_range(-1, 1) * exp(-dt / 0.006)
		# Pasa-altos tosco: deja el chasquido seco.
		var hp := s - prev
		prev = s
		data[i] = hp + 0.25 * sin(TAU * 80.0 * t) * exp(-t / 0.05)
	return _normalize(data, 0.55)


static func _paper(seconds: float) -> PackedFloat32Array:
	var data := _buffer(seconds)
	var lp := 0.0
	var prev := 0.0
	var bumps := [_rng.randf_range(0.0, 0.08), _rng.randf_range(0.1, 0.18), _rng.randf_range(0.2, 0.26)]
	for i in data.size():
		var t := float(i) / MIX_RATE
		var n := _rng.randf_range(-1, 1)
		lp += (n - lp) * 0.35          # pasa-bajos
		var bp := lp - prev            # + pasa-altos = banda
		prev = lp
		var env := 0.0
		for b in bumps:
			env += exp(-pow((t - b) / 0.035, 2.0))
		data[i] = bp * env
	return _normalize(data, 0.35)


static func _coins() -> PackedFloat32Array:
	var data := _buffer(0.45)
	var hits := [[0.0, 1.0], [0.075, 0.7], [0.16, 0.4]]
	var partials := [[2380.0, 1.0, 0.16], [3570.0, 0.6, 0.11], [5120.0, 0.35, 0.07], [6890.0, 0.2, 0.05]]
	for i in data.size():
		var t := float(i) / MIX_RATE
		var s := 0.0
		for h in hits:
			var dt: float = t - h[0]
			if dt < 0.0:
				continue
			for p in partials:
				s += h[1] * p[1] * sin(TAU * p[0] * (1.0 + 0.01 * h[1]) * dt) * exp(-dt / p[2])
		data[i] = s
	return _normalize(data, 0.32)


static func _click() -> PackedFloat32Array:
	var data := _buffer(0.04)
	for i in data.size():
		var t := float(i) / MIX_RATE
		data[i] = sin(TAU * 1400.0 * t) * exp(-t / 0.006) + _rng.randf_range(-0.3, 0.3) * exp(-t / 0.002)
	return _normalize(data, 0.18)


static func _thud() -> PackedFloat32Array:
	var data := _buffer(0.5)
	var lp := 0.0
	for i in data.size():
		var t := float(i) / MIX_RATE
		lp += (_rng.randf_range(-1, 1) - lp) * 0.05
		data[i] = sin(TAU * 52.0 * t) * exp(-t / 0.12) + lp * 2.0 * exp(-t / 0.05)
	return _normalize(data, 0.75)


static func _normalize(data: PackedFloat32Array, gain: float) -> PackedFloat32Array:
	var peak := 0.0001
	for v in data:
		peak = maxf(peak, absf(v))
	var k := gain / peak
	# Rampa de 5 ms al final para evitar el "clic" de corte.
	var fade := int(0.005 * MIX_RATE)
	for i in data.size():
		var tail := minf(1.0, float(data.size() - 1 - i) / fade)
		data[i] = data[i] * k * tail
	return data


static func _to_wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
