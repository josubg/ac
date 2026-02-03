class_name MissionResolutionWindow extends Control 

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var mision_status: Label = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/MisionStatus
@onready var rich_text_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/RichTextLabel
@onready var end_mission_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/EndMissionButton


var mission : Mission

func _ready() -> void:
	self.hide()

func show_mission(new_mission: Mission) -> void:
	print("show mission resolved: ", new_mission.status)
	title_label.text = new_mission.titulo
	description_label.text = new_mission.mision
	if new_mission.success():
		mision_status.text = "EXITO"
	else:
		mision_status.text = "FRACASO"
	self.show()

func _on_end_mission_button_pressed() -> void:
	self.mission = null
	self.hide()
