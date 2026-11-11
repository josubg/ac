extends SceneTree
## Herramienta de desarrollo: recorre las pantallas del juego y guarda capturas.
## No forma parte del juego (excluida de la exportación web).
##
## Uso:
##   Godot --path . --resolution 1920x1080 --script res://tools/ui_capture.gd -- --out=/ruta/salida
##   (opcional) --only=menu,main,...  --lang=en

var out_dir := "user://ui_capture"
var only: PackedStringArray = []
var lang := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--only="):
			only = arg.substr(7).split(",")
		elif arg.begins_with("--lang="):
			lang = arg.substr(7)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run()


func _want(name: String) -> bool:
	return only.is_empty() or name in only


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	if img.get_width() != 1920:
		img.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	print("ui_capture: ", path)


func _goto(path: String) -> Node:
	change_scene_to_file(path)
	await process_frame
	if lang != "":
		TranslationServer.set_locale(lang)
	await process_frame
	return current_scene


func _run() -> void:
	if lang != "":
		TranslationServer.set_locale(lang)
	await _wait(0.5)
	var gm = root.get_node("GameManager")
	var mm = root.get_node("MissionManager")
	var bm = root.get_node("BuildingManager")
	var tm = root.get_node("TimeManager")

	if _want("logos"):
		await _goto("res://scenes/logos_intro.tscn")
		await _wait(2.0)
		await _shot("01_logos")

	if _want("menu"):
		var menu = await _goto("res://scenes/menu_inicio.tscn")
		await _wait(1.0)
		await _shot("02_menu")
		menu.get_node("TutorialCanvas").visible = true
		await _shot("03_tutorial")
		menu.get_node("TutorialCanvas").visible = false
		menu.get_node("CreditosCanvas").visible = true
		await _shot("04_creditos")
		menu.get_node("CreditosCanvas").visible = false
		menu._on_options_button_pressed()
		await _shot("04b_opciones")
		menu.opciones.visible = false

	if _want("main"):
		gm.start_game()
		await process_frame
		await process_frame
		var main = current_scene
		await _wait(1.0)
		# Desplegar unas cuantas misiones para ver los lacres
		var days: Array = mm.scheduled_missions.keys()
		days.sort()
		var deployed: Array = []
		for d in days.slice(0, 4):
			for m in mm.scheduled_missions[d].duplicate():
				mm.deploy_mission(m)
				deployed.append(m)
		await _wait(0.5)
		tm.pause()
		await _shot("05_juego")

		var m0 = deployed[0]
		main.get_node("CanvasLayerMission/MissionWindow").show_mission(m0)
		await _wait(0.4)
		await _shot("06_mision")
		main.get_node("CanvasLayerMission/MissionWindow").hide()

		m0.status = m0.MISSION_STATUS.succeded
		m0.rey = 5
		m0.clero = -3
		var res = main.get_node("CanvasLayerMission/MissionResolutionWindow")
		res.show_mission(m0)
		await _shot("07_resolucion_exito")
		m0.status = m0.MISSION_STATUS.failed
		res.show_mission(m0)
		await _shot("08_resolucion_fracaso")
		res.hide()

		var bw = main.get_node("CanvasLayerMission/BuildingWindow")
		bw.setup(bm.buildings[0])
		await _shot("09_edificio")
		bw.hide()

		for b in bm.buildings.slice(0, 2):
			b.owner = b.Owner.PLAYER
		var pw = main.get_node("CanvasLayerMission/PropertiesWindow")
		pw.setup()
		await _shot("10_propiedades")
		pw.hide()
		for b in bm.buildings.slice(0, 2):
			b.owner = b.Owner.CITY

		main.get_node("CanvasLayerMission/MonjaSpeak").mensaje("MONJA_REY_3")
		await _wait(1.0)
		await _shot("11_monja")
		mm.end()

	if _want("end"):
		await _goto("res://scenes/game_over.tscn")
		await _wait(3.6)
		await _shot("12_derrota")
		var go = current_scene
		go.get_node("Label").hide()
		go.get_node("LabelGO").show()
		go.get_node("AnimationPlayer").stop()
		go.get_node("LabelGO").modulate = Color.WHITE
		await _shot("12b_derrota_final")
		await _goto("res://scenes/game_end.tscn")
		await _wait(3.6)
		await _shot("13_victoria")
		var fin = current_scene
		fin.get_node("Label").hide()
		fin.get_node("LabelGO").show()
		fin.get_node("AnimationPlayer").stop()
		fin.get_node("LabelGO").modulate = Color.WHITE
		await _shot("13b_victoria_final")

	quit()
