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
	print("Clave recibida: ", text)
	print("Traducción encontrada: ", tr(text))
	$Label.text = text
	mostrar()
