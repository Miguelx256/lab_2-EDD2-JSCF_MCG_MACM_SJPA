extends Node2D
const NodoServidor = preload("res://minijuegos/BFS DFS/BFS DFS.tscn")

# --- Configuración general ---
@export var cantidad_nodos: int = 6
@export var conexiones_por_nodo: int = 2

var grafo = {}
var posiciones = {}
var nodos = {}
var aristas = []
var visitados = []
var modo = ""
var nodo_infectado = null
var graph_node: Node2D


func _ready():
	randomize()
	
	# Crear contenedor del grafo
	graph_node = Node2D.new()
	graph_node.name = "Graph"
	add_child(graph_node)

	_crear_grafo_aleatorio()

	$"bfs button".pressed.connect(_on_bfs_pressed)
	$"dfs button".pressed.connect(_on_dfs_pressed)
	$Label.text = "Selecciona BFS o DFS para iniciar el rastreo."

func elegir_nodo_infectado():
	if nodos.size() == 0:
		push_error("No hay nodos para infectar.")
		return
	var claves = nodos.keys()
	var clave_random = claves[randi() % claves.size()]
	nodo_infectado = nodos[clave_random]
	
	print("Nodo infectado:", nodo_infectado.nombre)
# --- Generación del grafo ---

	return Vector2.ZERO
func _crear_grafo_aleatorio():
	var nombres = []
	for i in range(cantidad_nodos):
		nombres.append("Nodo_%d" % i)
	
	# Generar posiciones aleatorias (distribuidas)
	for nombre in nombres:
		posiciones[nombre] =  Vector2(
			randf_range(100, 700),
			randf_range(100, 500)
		)
	
	# Generar conexiones aleatorias (grafo no dirigido)
	for origen in nombres:
		grafo[origen] = []
	
	for origen in nombres:
		while grafo[origen].size() < conexiones_por_nodo:
			var destino = nombres[randi() % cantidad_nodos]
			if destino != origen and not destino in grafo[origen]:
				grafo[origen].append(destino)
				grafo[destino].append(origen)
	
	# Crear nodos visuales
	for nombre in grafo.keys():
		var nodo = NodoServidor.instantiate()
		nodo.position = posiciones[nombre]
		nodo.nombre = nombre
		graph_node.add_child(nodo)
		nodos[nombre] = nodo
	
	# Dibujar aristas
	for origen in grafo.keys():
		for destino in grafo[origen]:
			if not _existe_arista(origen, destino):
				var linea = Line2D.new()
				linea.width = 3
				linea.default_color = Color(0.6, 0.6, 1.0)
				linea.points = [posiciones[origen], posiciones[destino]]
				graph_node.add_child(linea)
				aristas.append({
					"origen": origen,
					"destino": destino,
					"linea": linea
				
				})
	elegir_nodo_infectado()
	


func _existe_arista(a, b) -> bool:
	for edge in aristas:
		if (edge.origen == a and edge.destino == b) or (edge.origen == b and edge.destino == a):
			return true
	return false


# --- Botones ---
func _on_bfs_pressed():
	modo = "BFS"
	_reiniciar()
	var inicio = nodos.keys()[randi() % nodos.size()]
	await _bfs(inicio)
	$Label.text = "Rastreo completado desde %s y el nodo infectado fue nodo_infectado" % inicio


func _on_dfs_pressed():
	modo = "DFS"
	_reiniciar()
	var inicio = nodos.keys()[randi() % nodos.size()]
	await _dfs(inicio)
	$Label.text = "Rastreo completado desde %s." % inicio


# --- Reutilizables ---
func _reiniciar():
	visitados.clear()
	for n in nodos.values():
		n.reiniciar_color()
	for e in aristas:
		e.linea.default_color = Color(0.6, 0.6, 1.0)


# --- BFS animado ---
func _bfs(inicio: String) -> void:
	var cola = [inicio]
	while cola.size() > 0:
		var nodo = cola.pop_front()
		if nodo in visitados:
			continue
		visitados.append(nodo)
		nodos[nodo].marcar_visitado()
		
		# Colorear líneas hacia los vecinos
		for vecino in grafo[nodo]:
			_colorear_arista(nodo, vecino)
			if not vecino in visitados:
				cola.append(vecino)
		await get_tree().create_timer(0.5).timeout
		if nodo_infectado:
			nodo_infectado.modulate=Color(1,0,0)
			$Label4.text = "Nodo infectado: %s" % nodo_infectado.nombre



# --- DFS animado ---
func _dfs(nodo: String) -> void:
	if nodo in visitados:
		return
	visitados.append(nodo)
	nodos[nodo].marcar_visitado()
	
	for vecino in grafo[nodo]:
		_colorear_arista(nodo, vecino)
		await get_tree().create_timer(0.5).timeout
		await _dfs(vecino)
	if nodo_infectado:
		nodo_infectado.modulate= Color(1,0,0)
		$Label4.text = "Nodo infectado: %s" % nodo_infectado.nombre


# --- Colorea la línea que une dos nodos ---
func _colorear_arista(a, b):
	for e in aristas:
		if (e.origen == a and e.destino == b) or (e.origen == b and e.destino == a):
			e.linea.default_color = Color(1.0, 0.6, 0.3)
			break
