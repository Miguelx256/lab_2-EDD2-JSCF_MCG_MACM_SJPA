extends Node2D

func _ready():
	var grafo := generar_grafo_conexo()

	var gv := preload("res://minijuegos/Caminos Mínimos/grafo_visual.tscn").instantiate()
	gv.set_grafo(grafo)
	add_child(gv)


func generar_grafo_conexo() -> Grafo:
	var grafo := Grafo.new()

	var num_nodos: int = randi_range(5, 10)
	var nodos: Array[Nodo] = []

	# Crear nodos
	for i in range(num_nodos):
		var nodo := Nodo.new(str(i))
		grafo.agregar_nodo(nodo)
		nodos.append(nodo)

	# Conexión mínima (camino lineal)
	for i in range(num_nodos - 1):
		grafo.conectar_nodo(
			nodos[i],
			nodos[i + 1],
			randf_range(1.0, 10.0)
		)

	# Aristas extra
	var extra_edges: int = randi_range(1, 2)

	for _i in range(extra_edges):
		var a: Nodo = nodos[randi_range(0, num_nodos - 1)]
		var b: Nodo = nodos[randi_range(0, num_nodos - 1)]

		if a != b:
			grafo.conectar_nodo(a, b, randf_range(1.0, 10.0))

	return grafo
