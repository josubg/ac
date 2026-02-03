class_name MissionResolutionWindow extends Control 

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var outcome_description: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/OutcomeDescription
@onready var outcome_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/OutcomeLabel
@onready var end_mission_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/EndMissionButton


var mission : Mission

func _ready() -> void:
	self.hide()

func show_mission(new_mission: Mission) -> void:
	self.mission = new_mission
	print("show mission resolved: ", self.mission.status)
	title_label.text = self.mission.titulo
	description_label.text = self.mission.mision
	if self.mission.success():
		outcome_label.text = "Exito"
		outcome_description.text = mission.success_text
	else:
		outcome_label.text = "Fracaso"
		outcome_description.text = mission.failed_text
	self.show()

func _on_end_mission_button_pressed() -> void:
	MissionManager.review_mision(self.mission)
	self.mission = null
	self.hide()
