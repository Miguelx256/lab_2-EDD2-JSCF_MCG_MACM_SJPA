extends Node2D

# --- PRELOADS ---
const NodoVisual = preload("res://minijuegos/BFS DFS/BFS DFS.tscn")
const NodoLogico = preload("res://core/Nodo.gd")
const Grafo = preload("res://core/Grafo.gd")

# --- CONFIG ---
@export var cantidad_nodos: int = 6
@export var conexiones_por_nodo: int = 2

# --- VARIABLES ---
var grafo_logico : Grafo
var posiciones = {}     # dato -> Vector2
var nodos = {}          # dato -> nodo visual
var aristas = []        # lista de diccionarios {origen: Nodo, destino: Nodo, linea: Line2D}
var visitados = []
var nodo_infectado = null   # nodo visual
var graph_node: Node2D
@onready var next_lvl: Button = $NextLvl
@onready var bg: CanvasLayer = $BG
@onready var bfs_dfs: TextureRect = $BG/BfsDfs

func _ready():
	bg.layer = -100  # dibuja detrás de todo
	bfs_dfs.set_anchors_preset(Control.PRESET_FULL_RECT)
	bfs_dfs.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bfs_dfs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	next_lvl.hide()

	grafo_logico = Grafo.new()

	graph_node = Node2D.new()
	graph_node.name = "Graph"
	add_child(graph_node)

	_crear_grafo_aleatorio()

	$"bfs button".pressed.connect(_on_bfs_pressed)
	$"dfs button".pressed.connect(_on_dfs_pressed)
	$Label.text = "Los rastros de NEMESIS han infectado el firewall central
	Misión: Selecciona BFS o DFS para iniciar el rastreo y encontrar la raiz del virus."
	$Label4.text = ""


# --------------------------------------------------------
#               GENERACIÓN DEL GRAFO (CORREGIDO)
# --------------------------------------------------------
func _crear_grafo_aleatorio():
	# 1. Crear nodos lógicos y añadirlos al grafo (Nodo.dato será el nombre)
	for i in range(cantidad_nodos):
		var etiqueta = "Nodo_%d" % i
		var nodo_temp = NodoLogico.new(etiqueta)  # Nodo.gd usa 'dato' en _init
		# usar el método que exista en tu Grafo (agregar_nodo / anadir_nodo)
		if grafo_logico.has_method("agregar_nodo"):
			grafo_logico.agregar_nodo(nodo_temp)
		elif grafo_logico.has_method("anadir_nodo"):
			grafo_logico.anadir_nodo(nodo_temp)
		else:
			push_error("La clase Grafo no tiene método para añadir nodos (agregar_nodo/anadir_nodo).")
			return

	# 2. Crear posiciones visuales (usando nodo.dato)
	for nodo in grafo_logico.lista_adyacencia:
		# nodo es objeto Nodo; su texto está en nodo.dato
		posiciones[nodo.dato] = Vector2(
			randf_range(100, 700),
			randf_range(100, 500)
		)

	# 3. Generar conexiones lógicas (trabajando con objetos Nodo)
	for nodo in grafo_logico.lista_adyacencia:
		# asegurar que usamos la lista de adyacentes del propio objeto (nodo.adyacente)
		while nodo.adyacente.size() < conexiones_por_nodo:
			var otros = grafo_logico.lista_adyacencia
			var candidato = otros[randi() % otros.size()]
			if candidato != nodo and not candidato in nodo.adyacente:
				# llamar al método correcto para crear arista (conectar_nodo / anadir_arista)
				if grafo_logico.has_method("conectar_nodo"):
					grafo_logico.conectar_nodo(nodo, candidato)
				elif grafo_logico.has_method("anadir_arista"):
					grafo_logico.anadir_arista(nodo, candidato)
				else:
					push_error("La clase Grafo no tiene método para crear aristas (conectar_nodo/anadir_arista).")
					return

	# 4. Crear nodos visuales (usamos nodo.dato como clave)
	for nodo in grafo_logico.lista_adyacencia:
		var nodo_vis = NodoVisual.instantiate()
		nodo_vis.position = posiciones[nodo.dato]
		# en el visual, deja la etiqueta (propiedad que tiene tu escena visual)
		# si tu NodoVisual espera 'nombre', asigna también
		if nodo_vis.has_method("set_nombre"):
			nodo_vis.set_nombre(nodo.dato)
		else:
			# muchos ejemplos usan 'nombre' como export var; prueba asignar si existe
			if "nombre" in nodo_vis:
				nodo_vis.nombre = nodo.dato

		graph_node.add_child(nodo_vis)
		nodos[nodo.dato] = nodo_vis

	# 5. Dibujar aristas visuales (iterando los adyacentes de cada nodo)
	for nodo in grafo_logico.lista_adyacencia:
		for vecino in nodo.adyacente:
			if not _arista_ya_creada(nodo, vecino):
				var linea = Line2D.new()
				linea.width = 3
				linea.default_color = Color(0.6, 0.6, 1.0)
				# posiciones usan claves string (dato)
				linea.points = [posiciones[nodo.dato], posiciones[vecino.dato]]
				graph_node.add_child(linea)
				aristas.append({
					"origen": nodo,
					"destino": vecino,
					"linea": linea
				})

	# Finalmente elegir nodo infectado (se coloreará AL FINAL del recorrido)
	elegir_nodo_infectado()


func elegir_nodo_infectado():
	# nodos es Dictionary dato -> nodo_visual
	var claves = nodos.keys()
	var clave_random = claves[randi() % claves.size()]
	nodo_infectado = nodos[clave_random]
	print("Nodo infectado: ", clave_random)


func _arista_ya_creada(a, b) -> bool:
	for e in aristas:
		if (e.origen == a and e.destino == b) or (e.origen == b and e.destino == a):
			return true
	return false


# --------------------------------------------------------
#               BOTONES (BFS / DFS)
# --------------------------------------------------------
func _on_bfs_pressed():
	_reiniciar()
	# escoger un nodo lógico de inicio
	var lista_nodos = grafo_logico.lista_adyacencia
	var inicio = lista_nodos[randi() % lista_nodos.size()]
	await _bfs(inicio)  # pasamos objeto Nodo lógico
	# colorear infectado y mostrar etiqueta
	if nodo_infectado:
		nodo_infectado.modulate = Color(1, 0, 0)
	$Label.text = "Rastreo BFS desde %s" % inicio.dato
	$Label4.text = "Rastreo completado. Has encontrado el nodo raíz del virus."

func _on_dfs_pressed():
	_reiniciar()
	var lista_nodos = grafo_logico.lista_adyacencia
	var inicio = lista_nodos[randi() % lista_nodos.size()]
	await _dfs(inicio)
	if nodo_infectado:
		nodo_infectado.modulate = Color(1, 0, 0)
	$Label.text = "Rastreo DFS desde %s" % inicio.dato
	$Label4.text = "Rastreo completado. Has encontrado el nodo raíz del virus.
    Siguiente misión: calcular la ruta más segura para aislarlo."


# --------------------------------------------------------
#                       REINICIAR
# --------------------------------------------------------
func _reiniciar():
	visitados.clear()
	for n in nodos.values():
		if n.has_method("reiniciar_color"):
			n.reiniciar_color()
		else:
			# intentar resetear modulate
			n.modulate = Color(1,1,1)

	for e in aristas:
		e.linea.default_color = Color(0.6, 0.6, 1.0)


# --------------------------------------------------------
#                         BFS (trabaja con objetos Nodo)
# --------------------------------------------------------
func _bfs(inicio_nodo) -> void:
	var cola = [inicio_nodo]

	while cola.size() > 0:
		var actual = cola.pop_front()
		if actual in visitados:
			continue

		visitados.append(actual)
		var vis = nodos[actual.dato]
		if vis:
			if vis.has_method("marcar_visitado"):
				vis.marcar_visitado()
			else:
				vis.modulate = Color(0.2, 1, 0.2)

		for vecino in actual.adyacente:
			_colorear_arista(actual, vecino)
			if not vecino in visitados:
				cola.append(vecino)

		await get_tree().create_timer(0.4).timeout

	# Al final coloreamos el infectado (visual)
	if nodo_infectado:
		nodo_infectado.modulate = Color(1, 0, 0)
		$Label4.text = "Nodo infectado: %s" % nodo_infectado.name if nodo_infectado else ""

	# 👉 Aquí ya terminó BFS y el infectado está identificado visualmente
	next_lvl.show()


# --------------------------------------------------------
#                         DFS (trabaja con objetos Nodo)
# --------------------------------------------------------
func _dfs(nodo) -> void:
	if nodo in visitados:
		return

	visitados.append(nodo)
	var vis = nodos[nodo.dato]
	if vis:
		if vis.has_method("marcar_visitado"):
			vis.marcar_visitado()
		else:
			vis.modulate = Color(0.2, 1, 0.2)

	for vecino in nodo.adyacente:
		_colorear_arista(nodo, vecino)
		await get_tree().create_timer(0.4).timeout
		await _dfs(vecino)

	# al terminar, infectado rojo
	if nodo_infectado:
		nodo_infectado.modulate = Color(1, 0, 0)
		$Label4.text = "Nodo infectado: %s" % nodo_infectado.name if nodo_infectado else ""

	# ⚠️ OJO: esto se ejecuta varias veces por la recursión
	# mejor mostrar el botón una sola vez solo si aún está oculto:
	if next_lvl and not next_lvl.visible:
		next_lvl.show()



# --------------------------------------------------------
#                   COLOREAR ARISTA VISUAL
# --------------------------------------------------------
func _colorear_arista(a, b):
	for e in aristas:
		if (e.origen == a and e.destino == b) or (e.origen == b and e.destino == a):
			e.linea.default_color = Color(1.0, 0.6, 0.3)
			break


func _on_dfs_button_2_button_down() -> void:
	get_tree().change_scene_to_file("res://minijuegos/Caminos Mínimos/DIJKSTRA.tscn")
