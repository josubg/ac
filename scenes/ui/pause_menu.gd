extends CanvasLayer
## Menú de pausa de la partida: continuar, opciones y salir al menú.
## Se abre con Esc (main.gd) o con el botón de pausa del HUD.

@onready var resume_button: Button = $PanelContainer/Margin/Rows/ResumeButton
@onready var options_button: Button = $PanelContainer/Margin/Rows/OptionsButton
@onready var quit_button: Button = $PanelContainer/Margin/Rows/QuitButton
@onready var options: CanvasLayer = $Options

var _confirming_quit := false


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	options.closed.connect(_on_options_closed)


func open() -> void:
	if visible:
		return
	_set_confirming(false)
	visible = true
	TimeManager.pause(self)
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	options.close()
	visible = false
	TimeManager.resume(self)


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	# Esc con la carta de opciones abierta lo atiende la propia carta.
	if visible and not options.visible and event is InputEventKey \
			and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _on_options_pressed() -> void:
	$PanelContainer.visible = false
	options.open()


func _on_options_closed() -> void:
	$PanelContainer.visible = true
	options_button.grab_focus()


## Salir pierde la partida: el primer clic pide confirmación.
func _on_quit_pressed() -> void:
	if not _confirming_quit:
		_set_confirming(true)
		return
	TimeManager.resume(self)
	MissionManager.end()
	GameManager.go_to_menu()


func _set_confirming(value: bool) -> void:
	_confirming_quit = value
	quit_button.text = "UI_PAUSE_QUIT_CONFIRM" if value else "UI_PAUSE_QUIT"
