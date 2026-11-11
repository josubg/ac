extends SceneTree
## Comprueba la localización. Uso:
##   Godot --headless --path . --script res://tools/check_i18n.gd
## - keys usadas en escenas/scripts/datos que no tienen fila en rosetta.csv
## - filas de rosetta.csv que nadie usa
## - filas sin traducción en algún idioma (o idéntica a la key)
## - textos de escena (text/tooltip_text) que no son keys

const ROSETTA := "res://resources/i18n/rosetta.csv"
const LOCALES := ["es", "en"]
# Textos de escena que no se traducen a propósito (símbolos o marcadores que el código sobrescribe).
const SCENE_TEXT_WHITELIST := ["X", "0", "TIME LABEL"]
# Keys que se construyen en código a partir de un prefijo.
const DYNAMIC_PREFIXES := {"AGENT_FACTION_": ["NOBLE", "RELIGIOSA", "MALECHOR"]}

var key_re := RegEx.create_from_string("\"([A-Z][A-Z0-9]*_[A-Z0-9_]+)\"")
var data_key_re := RegEx.create_from_string("\\b([A-Z][A-Z0-9]*_[A-Z0-9_]+)\\b")
var text_re := RegEx.create_from_string("(?m)^(text|tooltip_text|placeholder_text) = \"((?:[^\"\\\\]|\\\\.)*)\"")
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
