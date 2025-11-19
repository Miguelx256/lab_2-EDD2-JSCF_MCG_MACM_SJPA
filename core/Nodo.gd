extends Node
# nodo.gd
class_name Nodo

static var cid: int = 0

var adyacente: Dictionary = {}  # Nodo -> peso
var dato: String
var id: int

func _init(_dato: String = ""):
	dato = _dato
	id = cid
	cid += 1


func agregar_adyacente(nodo: Nodo, peso: float) -> void:
	adyacente[nodo] = peso


func eliminar_adyacente(nodo: Nodo) -> void:
	adyacente.erase(nodo)
