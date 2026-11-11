class_name PropertiesWindow
extends Control

@onready var close_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/CloseButton

@onready var properties_list: VBoxContainer = $PanelContainer/VBoxContainer/ScrollContainer/PropertiesList
@onready var summary_label: Label = $PanelContainer/VBoxContainer/SummaryLabel

func refresh() -> void:
	# Limpiar la lista anterior
	for child in properties_list.get_children():
		child.queue_free()

	# Obtener propiedades del jugador
	var player_buildings := BuildingManager.get_player_buildings()

	print("Propiedades encontradas: ", player_buildings.size())

	# Calcular ingresos totales
	var total_income := 0

	for building in player_buildings:
		total_income += building.income_per_turn
		# Fila del edificio
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 100
		properties_list.add_child(row)

		# Imagen
		var image := TextureRect.new()
		image.custom_minimum_size = Vector2(100, 90)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture = building.image
		row.add_child(image)

		# Contenedor de información
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		# Nombre
		var name_label := Label.new()
		name_label.text = building.building_name
		info.add_child(name_label)

		# Ingresos
		var income_label := Label.new()
		income_label.text = tr("UI_PROPERTIES_DAILY_INCOME") % building.income_per_turn
		info.add_child(income_label)
		var influence_label := Label.new()
		influence_label.text = tr("UI_PROPERTIES_DAILY_INFLUENCE") % [building.influence_per_turn,tr(_get_faction_name(building.faction_influence))]
		info.add_child(influence_label)
		
		# Controles de donación
		var donation_controls := HBoxContainer.new()
		info.add_child(donation_controls)

		# Facción destinataria
		var faction_label := Label.new()
		var can_donate = true
		match building.faction_influence:
			&"rey":
				faction_label.text = "UI_PROPERTIES_FACTION_KING"
			&"nobleza":
				faction_label.text = "UI_PROPERTIES_FACTION_NOBILITY"
			&"clero":
				faction_label.text = "UI_PROPERTIES_FACTION_CLERGY"
			&"descontento":
				faction_label.text = "UI_PROPERTIES_FACTION_DISCONTENT"
			_:
				faction_label.text = "UI_PROPERTIES_NO_FACTION_ASSIGNED"
				can_donate = false

		donation_controls.add_child(faction_label)

		# Botón Donar
		var donate_button := Button.new()
		donate_button.text = "UI_PROPERTIES_DONATE"
		donate_button.disabled = not can_donate
		if not can_donate:
			donate_button.text = "FACTION_NONE"

		donation_controls.add_child(donate_button)

		var building_id := building.id
		donate_button.pressed.connect(_on_donate_pressed.bind(building_id))
	# Separador visual
	var separator := HSeparator.new()
	properties_list.add_child(separator)

	# Total de ingresos
	var total_label := Label.new()
	total_label.text = tr("UI_PROPERTIES_TOTAL_INCOME") % total_income
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_font_size_override("font_size", 20)

	properties_list.add_child(total_label)
	
func setup() -> void:
	refresh()
	show()
	TimeManager.pause()

func _on_close_button_pressed() -> void:
	hide()
	TimeManager.resume()

func _on_donate_pressed(building_id: String) -> void:
	if BuildingManager.donate_building(building_id):
		refresh()
	else:
		print("No se ha podido realizar la donación.")

func _get_faction_name(faction: StringName) -> String:
	match faction:
		&"rey":
			return "FACTION_KING"
		&"nobleza":
			return "FACTION_NOBILITY"
		&"clero":
			return "FACTION_CLERGY"
		&"descontento":
			return "FACTION_DISCONTENT"
		_:
			return "FACTION_NONE"
