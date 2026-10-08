class_name Building
extends Resource


enum Owner {
	CITY,
	PLAYER,
	FACTION
}


enum Status {
	ACTIVE,
	DESTROYED
}


@export_category("Identity")
@export var id: String
@export var building_name: String
@export_multiline var description: String


@export_category("State")
@export var owner: Owner = Owner.CITY
@export var status: Status = Status.ACTIVE
@export var available: bool = true


@export_category("Economy")
@export var purchase_cost: int = 0
@export var income_per_turn: int = 0


@export_category("Influence")
@export var faction_influence: StringName
@export var donation_influence: StringName

@export_category("Map")
@export var x: float = 0.0
@export var y: float = 0.0

var reconstruction_cost: int:
	get:
		return purchase_cost / 2
