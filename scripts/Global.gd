extends Node

var failed: bool
var mission_window


func start():
	get_tree().change_scene_to_file("res://main.tscn")
