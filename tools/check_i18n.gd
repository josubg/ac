extends SceneTree
## Comprueba la localización. Uso:
##   Godot --headless --path . --script res://tools/check_i18n.gd
## - keys usadas en escenas/scripts/datos que no tienen fila en rosetta.csv
## - filas de rosetta.csv que nadie usa
## - filas sin traducción en algún idioma (o idéntica a la key)
## - textos de escena (text/tooltip_text) que no son keys
## - textos asignados en .gd (`.text = "..."`, `mensaje("...")`) que no son keys
## - paridad es/en por fila: %s/%d (y su orden), etiquetas BBCode y saltos \n
## - filas con el inglés idéntico al español fuera de IDENTICAL_OK
## - (aviso, no cuenta como problema) espacios al principio/fin distintos entre idiomas
## Lee rosetta.csv y además el TranslationServer: tras editar el CSV, ejecuta antes `--import`.

const ROSETTA := "res://resources/i18n/rosetta.csv"
const LOCALES := ["es", "en"]
# Textos de escena que no se traducen a propósito (símbolos o marcadores que el código sobrescribe).
const SCENE_TEXT_WHITELIST := ["X", "0", "TIME LABEL", "Español", "English", "Domingo, 1 de Enero de 1640", "[center][color=#c0392b]C[/color]uatro [color=#c0392b]C[/color]ortes\n[i]Madrid, MDCXL[/i][/center]"]
# Filas cuyo inglés es igual al español a propósito (nombres propios, préstamos).
const IDENTICAL_OK := ["UI_MENU_TUTORIAL", "UI_TUTORIAL_TITLE", "AGENT_PACA_NAME", "AGENT_JUANITO_NAME",
	"AGENT_AMPARO_NAME", "AGENT_FACTION_NOBLE", "MISSION_022_TITLE"]
# Keys que se construyen en código a partir de un prefijo.
const DYNAMIC_PREFIXES := {"AGENT_FACTION_": ["NOBLE", "RELIGIOSA", "MALECHOR"]}

var key_re := RegEx.create_from_string("\"([A-Z][A-Z0-9]*_[A-Z0-9_]+)\"")
var data_key_re := RegEx.create_from_string("\\b([A-Z][A-Z0-9]*_[A-Z0-9_]+)\\b")
var text_re := RegEx.create_from_string("(?m)^(text|tooltip_text|placeholder_text) = \"((?:[^\"\\\\]|\\\\.)*)\"")
var gd_text_re := RegEx.create_from_string("(?:\\.(?:text|tooltip_text)\\s*=|mensaje\\()\\s*\"([^\"]*[a-záéíóúñ][^\"]*)\"")
var fmt_re := RegEx.create_from_string("%[-+0-9.]*[sdif]")
var bb_re := RegEx.create_from_string("\\[/?[a-z]+[^\\]]*\\]")
var problems := 0

func _init() -> void:
	var rows := _read_rosetta()
	var used := {}
	for path in _files("res://", ["gd", "tscn"]):
		if path.begins_with("res://tools/") or path.begins_with("res://addons/"):
			continue
		var src := FileAccess.get_file_as_string(path)
		for m in key_re.search_all(src):
			used[m.get_string(1)] = path
		if path.ends_with(".gd"):
			for m in gd_text_re.search_all(src):
				_problem("texto en script sin key en %s: \"%s\"" % [path, m.get_string(1).left(60)])
		if path.ends_with(".tscn"):
			for m in text_re.search_all(src):
				var value := m.get_string(2)
				if not rows.has(value) and value not in SCENE_TEXT_WHITELIST:
					_problem("texto de escena sin key en %s: %s = \"%s\"" % [path, m.get_string(1), value.left(60)])
	for data_path in ["res://resources/data/missions_v2.csv", "res://resources/data/buildings.txt"]:
		for m in data_key_re.search_all(FileAccess.get_file_as_string(data_path)):
			used[m.get_string(1)] = data_path
		for word in FileAccess.get_file_as_string(data_path).split(","):
			var w := word.strip_edges().trim_prefix("\"").trim_suffix("\"")
			if w.length() > 12 and w.contains(" "):
				_problem("texto sin key en %s: %s" % [data_path, w.left(60)])
	for prefix in DYNAMIC_PREFIXES:
		used.erase(prefix)
		for suffix in DYNAMIC_PREFIXES[prefix]:
			used[prefix + suffix] = "(dinámica)"

	for key in used:
		if not rows.has(key):
			_problem("key sin fila en rosetta: %s (%s)" % [key, used[key]])
	for key in rows:
		if not used.has(key):
			_problem("fila de rosetta sin uso: %s" % key)

	for key in rows:
		_check_parity(key, rows[key])

	# Traducciones cargadas de verdad por el TranslationServer
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		for key in rows:
			var t := TranslationServer.translate(key)
			if t == key or t.strip_edges().is_empty():
				_problem("[%s] sin traducción: %s" % [locale, key])
	TranslationServer.set_locale("es")
	print("check_i18n: %d keys en rosetta, %d usadas, %d problemas" % [rows.size(), used.size(), problems])
	quit(1 if problems > 0 else 0)

func _check_parity(key: String, row: PackedStringArray) -> void:
	var es: String = row[1]
	var en: String = row[2]
	if _matches(fmt_re, es) != _matches(fmt_re, en):
		_problem("formato distinto en %s: es %s / en %s" % [key, _matches(fmt_re, es), _matches(fmt_re, en)])
	if _matches(bb_re, es) != _matches(bb_re, en):
		_problem("BBCode distinto en %s" % key)
	if es.count("\\n") != en.count("\\n"):
		_problem("número de \\n distinto en %s: es %d / en %d" % [key, es.count("\\n"), en.count("\\n")])
	if es == en and key not in IDENTICAL_OK:
		_problem("inglés idéntico al español en %s (¿sin traducir?)" % key)
	if (es.begins_with(" ") != en.begins_with(" ")) or (es.ends_with(" ") != en.ends_with(" ")):
		print("  aviso: espacios al principio/fin distintos en %s" % key)

func _matches(re: RegEx, text: String) -> Array:
	var out := []
	for m in re.search_all(text):
		out.append(m.get_string())
	return out

func _read_rosetta() -> Dictionary:
	var rows := {}
	var f := FileAccess.open(ROSETTA, FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 3 and not line[0].is_empty():
			if rows.has(line[0]):
				_problem("key duplicada en rosetta: %s" % line[0])
			rows[line[0]] = line
	return rows

func _files(dir: String, exts: Array) -> Array:
	var out := []
	for sub in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			out.append_array(_files(dir.path_join(sub), exts))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in exts:
			out.append(dir.path_join(file))
	return out

func _problem(msg: String) -> void:
	problems += 1
	printerr("  " + msg)
