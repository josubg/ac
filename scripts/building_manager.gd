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
	# Saltamos la cabecera del archivo.
	file.get_line()
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var data := parse_csv_line(line)
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
		building.x = int(data[8].strip_edges())
		building.y = int(data[9].strip_edges())
		add_building(building)
	file.close()
	print(str(buildings.size())+" edificios cargados.")
	for build in buildings:
		print(build.building_name)

func parse_csv_line(line: String) -> Array[String]:
	var result: Array[String] = []
	var current_field := ""
	var inside_quotes := false
	for character in line:
		if character == '"':
			inside_quotes = not inside_quotes
			continue
		if character == "," and not inside_quotes:
			result.append(current_field.strip_edges())
			current_field = ""
		else:
			current_field += character
	result.append(current_field.strip_edges())
	return result

func get_player_income_breakdown() -> Dictionary:
	var breakdown: Dictionary = {
		"total": 0,
		"buildings": {}
	}

	for building in buildings:
		if building.owner == Building.Owner.PLAYER:
			breakdown["buildings"][building.building_name] = building.income_per_turn
			breakdown["total"] += building.income_per_turn

	print("FINAL BREAKDOWN: ", breakdown)

	return breakdown

func buy_building(building_id: String) -> bool:
	var building = get_building_by_id(building_id)
	if building == null:
		return false
	if not building.available:
		return false
	if building.owner != Building.Owner.CITY:
		return false
	if Player.riqueza < building.purchase_cost:
		return false
		Player.riqueza -= building.purchase_cost
	building.owner = Building.Owner.PLAYER
	
	return true
