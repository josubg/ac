extends Control

var assigned_agent = null

func _can_drop_data(position, data):
	# "data" es lo que envía el nodo arrastrado (el agente)
	return data.has("agent_id")

func _drop_data(position, data):
	# Asigna el agente a este slot
	assigned_agent = data
	$AgentPortrait.texture = data.texture


func _on_button_pressed() -> void:
	$"../../..".hide()
