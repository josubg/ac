extends Node

var buildings: Array[Building] = []

const BUILDINGS_FILE_PATH := "res://resources/data/buildings.txt"

func add_building(building: Building) -> void:
	if building == null:
		return
	buildings.append(building)

func get_building_by_id(building_id: String) -> Building:
	for building in buildings:
		if building.id == building_id:
			return building
	return null

func get_player_buildings() -> Array[Building]:
	var player_buildings: Array[Building] = []
	
	for building in buildings:
		if (building.owner == Building.Owner.PLAYER and building.status == Building.Status.ACTIVE):
			player_buildings.append(building)
	
	return player_buildings

func get_player_building_count() -> int:
	return get_player_buildings().size()


func get_player_income_per_turn() -> int:
	var total_income: int = 0
	
	for building in buildings:
		if (building.owner == Building.Owner.PLAYER and building.status == Building.Status.ACTIVE):
			total_income += building.income_per_turn
	
	return total_income

func load_buildings() -> void:
	var file := FileAccess.open(BUILDINGS_FILE_PATH, FileAccess.READ)

	if file == null:
		push_error("BuildingManager: No se pudo abrir %s" % BUILDINGS_FILE_PATH)
		return

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.is_empty():
			continue

		var data := line.split(",", false)

		if data.size() < 8:
			push_error("BuildingManager: Línea de building inválida: %s" % line)
			continue

		var building := Building.new()

		building.id = data[0].strip_edges()
		building.building_name = data[1].strip_edges().trim_prefix('"').trim_suffix('"')
		building.available = data[2].strip_edges().to_lower() == "true"
		building.purchase_cost = int(data[3].strip_edges())
		building.income_per_turn = int(data[4].strip_edges())

		building.faction_influence = StringName(data[5].strip_edges())
		building.donation_influence = StringName(data[6].strip_edges())

		building.description = data[7].strip_edges().trim_prefix('"').trim_suffix('"')

		add_building(building)

	file.close()
