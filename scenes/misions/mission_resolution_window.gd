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
	TimeManager.pause(self)
	self.mission = new_mission
	print("Mission resolution window: show mission [%s]" % self.mission.status)
	title_label.text = self.mission.titulo
	description_label.text = self.mission.mision
	if self.mission.success():
		outcome_label.text = "UI_RESOLUTION_SUCCESS"
		outcome_label.add_theme_color_override("font_color",Color.GREEN)
		outcome_description.text = tr(mission.success_text) +"\n"+ get_results_text(mission)
	else:
		outcome_label.text = "UI_RESOLUTION_FAILURE"
		outcome_label.add_theme_color_override("font_color",Color.DARK_RED)
		outcome_description.text = mission.failed_text
	self.show()

func _on_end_mission_button_pressed() -> void:
	TimeManager.resume(self)
	MissionManager.review_mision(self.mission)
	self.mission = null
	self.hide()

func get_results_text(mission: Mission) -> String:
	var text = "\n"
	if mission.rey > 0:
		text = text + tr("RESULT_KING_PLEASED") + " \n"
	elif  mission.rey < 0:
		text = text + tr("RESULT_KING_DISPLEASED") + " \n"
	if mission.clero > 0:
		text = text + tr("RESULT_CHURCH_PLEASED") + " \n" 
	elif mission.clero < 0:
		text = text + tr("RESULT_CHURCH_OFFENDED") + " \n" 
	if mission.nobleza > 0:
		text = text + tr("RESULT_NOBILITY_PLEASED") + " \n" 
	elif mission.nobleza < 0:
		text = text + tr("RESULT_NOBILITY_RESENTFUL") + " \n" 
	if mission.descontento < 0:
		text = text + tr("RESULT_DISCONTENT_UP") + " \n" 
	elif mission.descontento > 0:
		text = text + tr("RESULT_DISCONTENT_DOWN") + " \n" 
	return text
