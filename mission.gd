extends TextureButton

class_name Mission
@export var start: float
@export var life: float

@export var influencia: int
@export var descontento: int
@export var nobleza: int
@export var iglesia: int
@export var rey: int

@export var debrief: String
var exito: bool
var fin: bool


func _ready():
	self.visible = false
	await get_tree().create_timer(start).timeout
	deploy()
	await get_tree().create_timer(life).timeout
	retire()
	
	
func deploy():
	print("Mission started")
	self.visible = true
	self.exito = false
	self.fin = false
	
	
func retire():
	if not self.fin:
		if exito:
			print("Mission succesfull")
			Global.influencia += self.influencia
			Global.descontento += self.descontento
			Global.nobleza += self.nobleza
			Global.iglesia += self.iglesia
			Global.rey += self.rey
		else: 
			print("Mission failed")
			Global.influencia-= self.influencia
			Global.descontento -= self.descontento
			Global.nobleza -= self.nobleza
			Global.iglesia -= self.iglesia
			Global.rey -= self.rey	
		self.visible = false
		self.fin = true


func _on_focus_entered() -> void:
	GameManager.show_mission(self)


func _on_mouse_entered() -> void:
	GameManager.show_mission(self)


func _on_mouse_exited() -> void:
	GameManager.clear_mission()


func _on_pressed() -> void:
	$"../../../MissionWindow".show()
	self.exito = true
	retire()
