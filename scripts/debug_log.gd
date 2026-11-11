class_name DebugLog
## Trazas de desarrollo: solo se escriben en builds de depuración (editor o export debug),
## así la versión publicada no llena la consola del navegador.

static func log(...args: Array) -> void:
	if OS.is_debug_build():
		print("".join(args.map(func(a): return str(a))))
