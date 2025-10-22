extends TextureRect

class_name Mission
@export var start: float
@export var life: float

func _ready():
	await get_tree().create_timer(start).timeout
	deploy()
	await get_tree().create_timer(life).timeout
	retire()
	
	
func deploy():
	print("Mission started")
	self.visible = true
	
	
	
func retire():
	print("Mission ended")
	self.visible = false
