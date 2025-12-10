extends Node

var failed: bool
var game_time: float = 300
var mission_window


func start():
	get_tree().change_scene_to_file("res://main.tscn")
