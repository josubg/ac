extends Node
## Guion de la demo de juice (ver juice_showcase.gd).

const OUT_DIR := "res://docs/vfx/"
var main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_run()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(file: String) -> void:
	if "--no-shots" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	img.save_jpg(ProjectSettings.globalize_path(OUT_DIR + file + ".jpg"), 0.85)
	print("Showcase: captura ", file, " frame ", Engine.get_frames_drawn())


func _run() -> void:
	await _wait(0.8)
	# --reduce-motion tras "--" en la línea de comandos: misma demo sin movimiento.
	var calm := "--reduce-motion" in OS.get_cmdline_user_args()
	Juice.set_reduce_motion(calm)
	GameManager.start_game()
	await _wait(1.0)
	main = get_tree().current_scene
	print("Showcase: escena ", main.name)

	# Misiones de los primeros días, sacadas antes de tiempo.
	var pending: Array = []
	var days := MissionManager.scheduled_missions.keys()
	days.sort()
	for d in days:
		for m in MissionManager.scheduled_missions[d]:
			pending.append(m)
	var a: Mission = pending[0]
	var b: Mission = pending[1]
	var c: Mission = pending[2]

	# 1. Aparece un rumor (lacre cae y suelta polvo).
	MissionManager.deploy_mission(a)
	await _wait(0.22)
	await _shot("01_lacre_aparece")
	MissionManager.deploy_mission(b)
	await _wait(0.3)
	MissionManager.deploy_mission(c)
	await _wait(0.8)

	# 2. Aviso: el lacre late.
	MissionManager.warn_mission(a)
	await _wait(0.2)
	await _shot("02_lacre_aviso")
	await _wait(0.6)

	# 3. Ventana de misión + agentes en los huecos.
	main._on_mission_pressed(b)
	await _wait(0.12)
	await _shot("03_ventana_entra")
	await _wait(0.4)
	var agents := main.find_children("*", "Agent", true, false)
	var roast: Node = main.mission_window.agent_roster
	for i in mini(2, roast.get_child_count()):
		roast.get_child(i).drop_data(Vector2.ZERO, agents[i])
		await _wait(0.12)
		if i == 1:
			await _shot("04_agente_en_hueco")
		await _wait(0.4)

	# 4. Enviar: sello y anillo de tinta.
	main.mission_window._on_send_pressed()
	await _wait(0.12)
	await _shot("05_enviar_sello")
	await _wait(0.8)

	# 5. Resultado: éxito.
	b.status = Mission.MISSION_STATUS.succeded
	MissionManager.resolve_mission(b)
	await _wait(0.25)
	await _shot("06_barras_y_lacre_resuelto")
	await _wait(1.2)
	main._on_mission_pressed(b)
	await _wait(0.45)
	await _shot("07_exito_dorado")
	await _wait(1.0)
	main.mission_resolution_window._on_end_mission_button_pressed()
	await _wait(0.5)

	# 6. Resultado: fracaso.
	for agent in agents.slice(2, 3):
		c.set_agent(agent)
	MissionManager.send_agents(c)
	await _wait(0.6)
	c.status = Mission.MISSION_STATUS.failed
	MissionManager.resolve_mission(c)
	await _wait(0.8)
	main._on_mission_pressed(c)
	await _wait(0.4)
	await _shot("08_fracaso_tinta")
	await _wait(1.0)
	_close_monja_legacy()
	main.mission_resolution_window._on_end_mission_button_pressed()
	await _wait(0.5)

	# 7. Caduca: el lacre se rompe.
	MissionManager.expire_mission(a)
	await _wait(0.07)
	await _shot("09_lacre_caduca")
	await _wait(1.0)

	# 8. Renta y compra de edificio.
	Player.riqueza += 3000
	await _wait(0.25)
	await _shot("10_renta_monedas")
	await _wait(0.8)
	for building in BuildingManager.buildings:
		if building.owner == Building.Owner.CITY and building.available and building.purchase_cost <= Player.riqueza:
			BuildingManager.buy_building(building.id)
			Player.riqueza = Player.riqueza  # fuerza la comprobación (como hace el juego al cobrar)
			break
	await _wait(0.3)
	await _shot("11_compra_edificio")
	await _wait(1.0)

	# 9. Descontento alto: viñeta.
	Player.descontento = 88
	await _wait(1.2)
	await _shot("12_descontento_alto")

	# 10. El Rey cruza el umbral: temblor, velo rojo y monja.
	# El Rey ya cruzó su primer umbral con el fracaso: ahora la Iglesia.
	Player.clero = 35
	await _wait(0.12)
	await _shot("13_iglesia_umbral")
	await _wait(1.2)
	await _shot("14_monja")
	_close_monja_legacy()
	await _wait(0.5)
	Player.nobleza = 15
	await _wait(0.6)
	_close_monja_legacy()
	await _wait(1.0)
	await _shot("15_barra_en_peligro")

	# 11. Reducir movimiento (F10).
	Juice.toggle_reduce_motion()
	await _wait(0.3)
	await _shot("16_reducir_movimiento")
	Juice.set_reduce_motion(calm)
	await _wait(1.0)

	# 12. Derrota y victoria.
	Player.rey = 0
	await _wait(2.5)
	await _shot("17_derrota_ceniza")
	GameManager.go_to_gameend()
	await _wait(2.5)
	await _shot("18_victoria_motas")
	await _wait(0.5)
	get_tree().quit()


func _close_monja_legacy() -> void:
	if main and is_instance_valid(main) and main.monja_mensaje and main.has_method("_close_monja_message"):
		main._close_monja_message()
		return
	if main and is_instance_valid(main) and main.monja_mensaje:
		main.monja_speak.ocultar()
		main.monja_mensaje = false
		TimeManager.resume()
