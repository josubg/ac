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
	TimeManager.pause()
	self.mission = new_mission
	print("Mission resolution window: show mission [%s]" % self.mission.status)
	title_label.text = self.mission.titulo
	description_label.text = self.mission.mision
	if self.mission.success():
		outcome_label.text = "Misión completada con Exito"
		outcome_label.add_theme_color_override("font_color",Color.GREEN)
		outcome_description.text = mission.success_text +"\n"+ get_results_text(mission)
	else:
		outcome_label.text = "La misión ha sido un Fracaso"
		outcome_label.add_theme_color_override("font_color",Color.DARK_RED)
		outcome_description.text = mission.failed_text
	self.show()

func _on_end_mission_button_pressed() -> void:
	TimeManager.resume()
	MissionManager.review_mision(self.mission)
	self.mission = null
	self.hide()

func get_results_text(mission: Mission) -> String:
	var text = "\n"
	if mission.rey > 0:
		text = text + "El Rey está satisfecho. \n"
	elif  mission.rey < 0:
		text = text + "El Rey no está satisfecho. \n"
	if mission.clero > 0:
		text = text + "La Iglesia está complacida. \n" 
	elif mission.clero < 0:
		text = text + "Hemos ofendido a la Iglesia. \n" 
	if mission.nobleza > 0:
		text = text + "La Nobleza está satisfecha. \n" 
	elif mission.nobleza < 0:
		text = text + "Algunos nobles se han resentido de nuestros actos. \n" 
	if mission.descontento < 0:
		text = text + "El descontento popular se ha incrementado. \n" 
	elif mission.descontento > 0:
		text = text + "El descontento popular se ha reducido. \n" 
	return text
