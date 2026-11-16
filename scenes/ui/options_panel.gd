extends CanvasLayer
## Carta de Opciones: idioma, volúmenes, pantalla completa y reducir movimiento.
## La usan el menú principal y el menú de pausa. Esc la cierra.

signal closed

const SETTINGS := "PanelContainer/VBoxContainer/Ajustes/"

@onready var language_buttons: Array[Button] = [
	get_node(SETTINGS + "Idioma/Espanol"),
	get_node(SETTINGS + "Idioma/English"),
]
## Deslizador -> bus de audio
@onready var volume_sliders: Dictionary[HSlider, String] = {
	get_node(SETTINGS + "VolumenGeneral"): "Master",
	get_node(SETTINGS + "VolumenMusica"): "Musica",
	get_node(SETTINGS + "VolumenEfectos"): "Efectos",
}
@onready var fullscreen_check: CheckBox = get_node(SETTINGS + "PantallaCompleta")
@onready var reduce_motion_check: CheckBox = get_node(SETTINGS + "ReducirMovimiento")
@onready var close_button: Button = $PanelContainer/VBoxContainer/Cabecera/CerrarButton


func _ready() -> void:
	for button in language_buttons:
		button.pressed.connect(_on_language_pressed.bind(String(button.get_meta("locale"))))
	for slider in volume_sliders:
		slider.value_changed.connect(func(v: float): Ajustes.set_volume(volume_sliders[slider], v))
	fullscreen_check.toggled.connect(Ajustes.set_fullscreen)
	reduce_motion_check.toggled.connect(Juice.set_reduce_motion)
	close_button.pressed.connect(close)
	_mark_language(TranslationServer.get_locale().substr(0, 2))


func open() -> void:
	_mark_language(TranslationServer.get_locale().substr(0, 2))
	for slider in volume_sliders:
		slider.set_value_no_signal(Ajustes.get_volume(volume_sliders[slider]))
	fullscreen_check.set_pressed_no_signal(Ajustes.is_fullscreen())
	reduce_motion_check.set_pressed_no_signal(Juice.reduce_motion)
	visible = true
	for button in language_buttons:
		if button.button_pressed:
			button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _on_language_pressed(locale: String) -> void:
	LocaleSettings.set_and_save(locale)
	_mark_language(locale)


func _mark_language(locale: String) -> void:
	for button in language_buttons:
		button.set_pressed_no_signal(button.get_meta("locale") == locale)
