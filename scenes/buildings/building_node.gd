class_name BuildingNode
extends Area2D

signal building_pressed(building: Building)
@onready var sprite_2d: Sprite2D = $Sprite2D

var building: Building

func _ready() -> void:
	sprite_2d.texture = building.image

func get_building() -> Building:
	return building
