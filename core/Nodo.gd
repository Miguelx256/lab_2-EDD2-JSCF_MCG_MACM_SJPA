# res://core/Nodo.gd
extends RefCounted
class_name Nodo

var dato:String
var id:int = -1
var adyacente:Dictionary = {}   # claves: Nodo, valor: peso (float)

func _init(_dato:String):
	dato = _dato
	# Si _dato es "0", "1", "2", ... sirve como id numérico
	if _dato.is_valid_int():
		id = int(_dato)


func agregar_adyacente(nodo: Nodo, peso: float) -> void:
	adyacente[nodo] = peso

func eliminar_adyacente(nodo: Nodo) -> void:
	adyacente.erase(nodo)
