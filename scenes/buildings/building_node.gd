class_name BuildingNode
extends Area2D

signal building_pressed(building: Building)

var building: Building

func get_building() -> Building:
	return building
