# res://core/Grafo.gd
extends RefCounted
class_name Grafo

var lista_adyacencia:Array = []   # Array de Nodo
var aristas:Array = []            # opcional, para Kruskal/Prim: [{a, b, peso}, ...]

func agregar_nodo(nodo:Nodo) -> void:
	if not lista_adyacencia.has(nodo):
		lista_adyacencia.append(nodo)

func conectar_nodo(a:Nodo, b:Nodo, peso:float = 1.0) -> void:
	# Grafo no dirigido con pesos en diccionario adyacente

	# Para a → b
	if not a.adyacente.has(b):
		a.adyacente[b] = peso
	else:
		a.adyacente[b] = peso   # por si quieres actualizar peso

	# Para b → a (simétrico)
	if not b.adyacente.has(a):
		b.adyacente[a] = peso
	else:
		b.adyacente[a] = peso

	# Guardar también en lista de aristas (si la usas para MST, etc.)
	aristas.append({
		"a": a,
		"b": b,
		"peso": peso
	})
