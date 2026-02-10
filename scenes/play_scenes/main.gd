extends Node

@onready var mission_window: Control = $CanvasLayerMission/MissionWindow
@onready var mission_resolution_window: Control = $CanvasLayerMission/MissionResolutionWindow

@onready var time_label: Label = $CanvasLayerMission/VBoxContainer/HBoxContainer/ColorRect/TimeLabel
@onready var rey_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer/ReyBar
@onready var nobleza_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer2/NoblezaBar
@onready var clero_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/influence_panel/VBoxContainer/HBoxContainer3/CleroBar
@onready var descontento_bar: ProgressBar = $CanvasLayerMission/VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer/DescontentoBar
@onready var buttons_layer: Control = $CanvasLayerMission/VBoxContainer/ButtonsLayer

@onready var active_missions: Dictionary[Mission, int] = {}
@onready var active_mission_buttons: Dictionary[Mission, MissionButton] = {}
@onready var monja_speak: Node = $CanvasLayerMission/MonjaSpeak

@onready var mission_button_scene: PackedScene = load("res://scenes/misions/MissionButton.tscn")
const BASE_RES = Vector2(1920, 1080)

var buttons: Array[MissionButton]= []
var monja_mensaje = false

func _ready() -> void:
	Player.clero_updated.connect(update_clero)
	Player.nobleza_updated.connect(update_nobleza)
	Player.rey_updated.connect(update_rey)
	Player.descontentoy_updated.connect(update_descontento)
	Player.rey_strike.connect(rey_strikes)
	Player.noble_strike.connect(nobleza_strikes)
	Player.iglesia_strike.connect(iglesia_strikes)
	
	MissionManager.added_mission.connect(mission_added)
	MissionManager.warning_mission.connect(mission_updated)
	MissionManager.clossed_mission.connect(mission_removed)
	MissionManager.load_missions("res://resources/data/missions.txt")
	print("Misions: " + str(MissionManager.scheduled_missions))
	# Test_Mission
	mission_added(MissionManager.get_test_mission())
	Player.start()
	monja_speak.ocultar()

func _process(_delta):
	if GameManager.playing():
		time_label.text = TimeManager.get_date()

func _input(event):
	if event is InputEventKey and event.pressed:
		if monja_mensaje:
			monja_speak.ocultar()
			TimeManager.resume()
			monja_mensaje = false
			set_process_input(false)
	elif event is InputEventMouseButton and event.pressed:
		if monja_mensaje:
			monja_speak.ocultar()
			TimeManager.resume()
			monja_mensaje = false
			set_process_input(false)
			
func mission_added(mission: Mission) -> void:
	print("Mision: " + str(mission.titulo))
	var button: MissionButton = mission_button_scene.instantiate()
	buttons.append(button)
	buttons_layer.add_child(button)
	var vp_size = get_viewport().get_visible_rect().size
	var pos = Vector2((mission.x / BASE_RES.x) * vp_size.x,(mission.y / BASE_RES.y) * vp_size.y)
	button.position = pos
	print("X"+str(mission.x))
	print("Y"+str(mission.y))
	print("X"+str(pos.x))
	print("Y"+str(pos.y))
	print("__________________")
	button.mission = mission
	button.mission_pressed.connect(_on_mission_pressed)
	
func mission_updated(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			if mission.on_course():
				button.set_on_course()
			if mission.resolved():
				button.set_resolved()
			else:
				button.set_warning()

func mission_removed(mission: Mission):
	for button in buttons: 
		if button.mission == mission: 
			buttons_layer.remove_child(button)
			buttons.erase(button)
			button.queue_free()

func update_rey(value):
	rey_bar.value = value
	_update_color(rey_bar, value,false)

func update_nobleza(value):
	nobleza_bar.value = value
	_update_color(nobleza_bar,value,false)

func update_clero(value):
	clero_bar.value = value
	_update_color(clero_bar, value,false)
	
func update_descontento(value):
	descontento_bar.value = value
	_update_color(descontento_bar,value,true)

func _update_color(faction : ProgressBar, value: float, inverse: bool) -> void:
	var color_ratio = value / 100.0
	var color = Color.RED.lerp(Color.GREEN, color_ratio)
	if inverse:
		color = Color.GREEN.lerp(Color.RED, color_ratio)
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0) # opcional, borde negro
	faction.add_theme_stylebox_override("background", style)
	
func _on_mission_pressed(mission: Mission) -> void:
	if mission.resolved():
		mission_resolution_window.show_mission(mission)
	else:
		mission_window.show_mission(mission)
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			GameManager.go_to_menu()

func rey_strikes(number):
	if number == 1:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, el Rey le ha enviado un mensaje: \n Por vuestras infinitas gestiones me quedo sin monterías, sin comedias y, lo que más duele, sin comediantas. Si he de ser rey de papeles y despachos, será porque vos habéis matado el campo, el teatro y la risa.")
		monja_mensaje = true
		set_process_input(true)		
	if number == 2:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, el Rey le ha enviado un mensaje: \n Conde Duque, vuestras faltas me persiguen aun en mis horas de reposo. Ni del gobierno hallo en vuestras manos sosiego, pues con vuestro desgobierno no hay oro, ni plata, ni tiempo para que yo me pueda dedicar a mis reales asuntos.")
		monja_mensaje = true
		set_process_input(true)	
	if number == 3:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, el Rey le ha enviado un mensaje: \n Gaspar, quedáis libres de vuestro oficio y de la carga que os pesaba. Podéis largaros de la Corte y ocuparos en vuestros propios enredos, que seguro no faltan. Bien os agradezco los servicios, aunque más me alegro de no veros más por aquí: que vuestra ausencia será el mayor favor que me hagáis.")	
		monja_mensaje = true
		set_process_input(true)	


func nobleza_strikes(number):
	if number == 1:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, hasta el caballerizo del príncipe —que apenas sabe leer— murmura que la próxima vez os negará el saludo. ¡Ni las bestias quieren ya vuestra sombra!")
		monja_mensaje = true
		set_process_input(true)		
	if number == 2:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, en los festejos de los Grandes se comenta que vuestra silla queda vacía. El vino corre, la música suena, pero vos no sois convidado, pues vuestra privanza huele a podredumbre.")
		monja_mensaje = true
		set_process_input(true)	
	if number == 3:
		TimeManager.pause()
		monja_speak.mensaje("Excelencia, han llegado cartas con firmas tan gruesas como los sellos de la Corte. Todas dicen lo mismo: que vuestra presencia es peste, y que no sois bienvenido en palacio. El papel arde fácil, y ya sabéis lo que sigue al fuego…")	
		monja_mensaje = true
		set_process_input(true)	
		
func iglesia_strikes(number):
	if number == 1:
		TimeManager.pause()
		monja_speak.mensaje("Las faltas que pesan sobre vuestra sombra no se borran con silencios ni favores. Bien sabéis que cada yerro exige su precio, y que serán muchas las misas que habrán de pagarse para redimir lo que vuestra mano ha sembrado.")
		monja_mensaje = true
		set_process_input(true)		
	if number == 2:
		TimeManager.pause()
		monja_speak.mensaje("Las faltas que pesan sobre vuestra conciencia no se lavan con oro ni con palabras. Bien sabéis que la Santa Madre Iglesia, espejo de Dios en la tierra, exige más que misas: pide discreción, recogimiento y penitencia verdadera Os conviene, pues, abrazar el cilicio y la flagelación, pues solo con sangre y silencio podrá vuestra alma congraciarse con la Iglesia, y en ello con el mismo Dios.")
		monja_mensaje = true
		set_process_input(true)	
	if number == 3:
		TimeManager.pause()
		monja_speak.mensaje("Ya no basta con misas ni con cilicios: todos saben lo que sois. Brujo de medianoche, judeizante de día, amigo de luteranos y mahometanos siempre. La Iglesia observa, y el fuego siempre aguarda paciente. Conviene que os guardéis con Dios, porque las lenguas son brasas y las brasas se han tornado para su Excelencia en una hoguera.")	
		monja_mensaje = true
		set_process_input(true)	
