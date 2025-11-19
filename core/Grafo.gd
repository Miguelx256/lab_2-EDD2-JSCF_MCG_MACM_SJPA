extends Node
class_name Grafo


const Nodo = preload("res://core/Nodo.gd")   # ← Ajusta la ruta real

var matriz_adyacencia: Array = []
var lista_adyacencia: Array[Nodo] = []


func _init():
	lista_adyacencia = []


func agregar_nodo(nodo: Nodo) -> void:
	if nodo not in lista_adyacencia:
		lista_adyacencia.append(nodo)

func conectar_nodo(n1: Nodo, n2: Nodo, peso: float = 1.0) -> void:
	# Inicializar matriz si está vacía
	if matriz_adyacencia.is_empty():
		var size := lista_adyacencia.size()
		matriz_adyacencia = []

		for i in range(size):
			matriz_adyacencia.append([])
			for j in range(size):
				matriz_adyacencia[i].append(0.0)

	# Conexiones en lista con peso
	n1.agregar_adyacente(n2, peso)
	n2.agregar_adyacente(n1, peso)

	# Conexión en matriz con peso
	matriz_adyacencia[n1.id][n2.id] = peso
	matriz_adyacencia[n2.id][n1.id] = peso
