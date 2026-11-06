extends Control

@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/NameLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var building_image: TextureRect = $PanelContainer/MarginContainer/VBoxContainer/BuildingImage
@onready var descr_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/DescrLabel
@onready var cost_label: Label = $PanelContainer/MarginContainer/VBoxContainer/CostLabel
@onready var buy_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BuyButton
@onready var income_label: Label = $PanelContainer/MarginContainer/VBoxContainer/IncomeLabel

var building: Building

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	buy_button.pressed.connect(_on_buy_pressed)
	hide()

func setup(building_data: Building) -> void:
	building = building_data
	refresh()
	show()

func refresh() -> void:
	if building == null:
		return

	name_label.text = building.building_name
	building_image.texture = building.image
	descr_label.text = building.description
	cost_label.text = "Coste: %d" % building.purchase_cost
	income_label.text = "Ingresos: %d por día" % building.income_per_turn

	var can_buy := (
		building.available
		and building.status == Building.Status.ACTIVE
		and building.owner == Building.Owner.CITY
		and Player.riqueza >= building.purchase_cost
	)

	buy_button.disabled = not can_buy

	if building.owner == Building.Owner.PLAYER:
		buy_button.text = "Ya es tuyo"
	elif building.status == Building.Status.DESTROYED:
		buy_button.text = "Destruido"
	elif not building.available:
		buy_button.text = "No disponible"
	elif Player.riqueza < building.purchase_cost:
		buy_button.text = "Fondos insuficientes"
	else:
		buy_button.text = "Comprar"

func _on_close_pressed() -> void:
	hide()

func _on_buy_pressed() -> void:
	if building == null:
		return
	if BuildingManager.buy_building(building.id):
		refresh()
	else:
		refresh()
