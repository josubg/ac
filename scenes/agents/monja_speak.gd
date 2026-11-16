extends Node


func ocultar():
	$TextureRect.hide()
	$TextureRect2.hide()
	$Label.hide()
	
func mostrar():
	$TextureRect.show()
	$TextureRect2.show()
	$Label.show()
	
func mensaje(text:String):
	$Label.text = text
	mostrar()
