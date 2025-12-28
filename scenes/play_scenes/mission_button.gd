extends TextureButton
class_name MissionButton

signal mission_pressed(mission: MissionData)

var mission: MissionData

func setup(m: MissionData) -> void:
	mission = m

func _pressed() -> void:
	print("PRESSED")
	emit_signal("mission_pressed", mission)


func _on_pressed() -> void:
	print("PRESSED")
	emit_signal("mission_pressed", mission)
