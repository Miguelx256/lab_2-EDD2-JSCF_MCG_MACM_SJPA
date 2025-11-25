extends Node2D

@onready var grafo_visual: Node2D = $CanvasLayer/Node2D
@onready var final: TextureRect = $CanvasLayer/Final
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var algo_label: Label = $CanvasLayer/Label
@onready var siguiente_button: Button = $CanvasLayer/siguiente
@onready var vida_nemesis_display: TextureRect = $CanvasLayer/VidaNemesisTextureRect 
@onready var nemesis: TextureRect = $CanvasLayer/NEMESIS


# -------------------- Clases externas -----------------------
@onready var Grafo = preload("res://core/Grafo.gd")
@onready var Nodo = preload("res://core/Nodo.gd")

var grafo
var etapa_mision_final: int = 1
var pantalla_ancho: int = 1152
var pantalla_alto: int = 648
var vida_nemesis_texturas: Array[Texture2D] = []
var NEMESIS_texturas: Array[Texture2D] = []

const INF = 1e9

func _ready() -> void:
	# Fondo en la capa de atrás
	canvas_layer.layer = -100
	if final:
		final.set_anchors_preset(Control.PRESET_FULL_RECT)
		final.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	grafo = Grafo.new()
	vida_nemesis_texturas.append(load("res://recursos/lifeBar0.png")) # Etapa 1
	vida_nemesis_texturas.append(load("res://recursos/lifeBar1.png")) # Etapa 2
	vida_nemesis_texturas.append(load("res://recursos/lifeBar2.png")) # Etapa 3
	vida_nemesis_texturas.append(load("res://recursos/lifeBar3.png")) # Etapa 4
	vida_nemesis_texturas.append(load("res://recursos/lifeBar4.png")) # Etapa 5 (Final)
	
	NEMESIS_texturas.append(load("res://recursos/virusSprite-0.png")) # Etapa 1
	NEMESIS_texturas.append(load("res://recursos/virusSprite-1.png")) # Etapa 2
	NEMESIS_texturas.append(load("res://recursos/virusSprite-2.png")) # Etapa 3
	NEMESIS_texturas.append(load("res://recursos/virusSprite-3.png")) # Etapa 4
	NEMESIS_texturas.append(load("res://recursos/virusSprite-4.png")) # Etapa 5
	_set_stage(1)

func _on_generar_grafo_button_down() -> void:
	_set_stage(1)
	generar_grafo_conexo_aleatorio()
	mostrar_grafo()
	grafo_visual.queue_redraw()

func _on_verificar_button_down() -> void:
	match etapa_mision_final:
		1:
			ejecutar_etapa_recorrido()
		2:
			ejecutar_etapa_camino_minimo()
		3:
			ejecutar_etapa_mst()
		4:
			ejecutar_etapa_flujo()
		5:
			_on_siguiente_button_pressed()
		_:
			if algo_label:
				algo_label.text = "¡Misión final completada!"

# ============================================================
# GENERACIÓN DE GRAFO CONEXO (5 nodos)
# ============================================================
func generar_grafo_conexo_aleatorio() -> void:
	# Reinicio de la estructura
	grafo.lista_adyacencia.clear()
	var total: int = 5
	var nodos_creados: Array[Nodo] = []

	# 1) Crear nodos
	for i in range(total):
		var n: Nodo = Nodo.new("N" + str(i))
		n.id = i
		grafo.agregar_nodo(n)
		nodos_creados.append(n)

	# 2) Conectividad base (árbol aleatorio)
	var conectados: Array[Nodo] = []
	var first: Nodo = nodos_creados.pop_back() as Nodo
	conectados.append(first)
	while nodos_creados.size() > 0:
		var nuevo: Nodo = nodos_creados.pop_back() as Nodo
		var existente: Nodo = conectados[randi() % conectados.size()] as Nodo
		var peso: float = randf_range(1.0, 100.0)
		grafo.conectar_nodo(existente, nuevo, peso)
		conectados.append(nuevo)

	# 3) Aristas extra aleatorias (evitando duplicados)
	var extras: int = randi() % 3
	for i in range(extras):
		var a: Nodo = grafo.lista_adyacencia[randi() % grafo.lista_adyacencia.size()] as Nodo
		var b: Nodo = grafo.lista_adyacencia[randi() % grafo.lista_adyacencia.size()] as Nodo
		if a == b: continue
		if a.adyacente.has(b) or b.adyacente.has(a): continue
		var peso2: float = randf_range(1.0, 100.0)
		grafo.conectar_nodo(a, b, peso2)

# ============================================================
# DIBUJAR / ACTUALIZAR GRAFO
# ============================================================
func mostrar_grafo() -> void:
	var posiciones: Array[Vector2] = []
	var aristas: Array = []
	var total: int = grafo.lista_adyacencia.size()
	if total == 0: return

	# Caja útil donde colocar los nodos
	var margen_superior: int = 70
	var margen_inferior: int = 120
	var x_min: int = 120
	var x_max: int = pantalla_ancho - 120
	var y_min: int = margen_superior + 40
	var y_max: int = pantalla_alto - margen_inferior - 40

	# Distribución elíptica
	var centro: Vector2 = Vector2((x_min + x_max) / 2.0, (y_min + y_max) / 2.0)
	var radio_x: float = (x_max - x_min) / 2.0
	var radio_y: float = (y_max - y_min) / 2.0
	var angulo: float = 0.0
	var inc: float = TAU / float(total)
	for _nodo in grafo.lista_adyacencia:
		var pos: Vector2 = centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y)
		posiciones.append(pos)
		angulo += inc

	# Reunir aristas (una vez por par i<j)
	for i in range(total):
		var nodo = grafo.lista_adyacencia[i]
		for vecino in nodo.adyacente.keys():
			var j: int = grafo.lista_adyacencia.find(vecino)
			if j == -1: continue
			if i < j:
				var peso: float = float(nodo.adyacente[vecino])
				aristas.append({ "a": i, "b": j, "weight": peso, "state": "normal" })

	# grafo_visual debe tener un método set_graph(posiciones, aristas)
	grafo_visual.set_graph(posiciones, aristas)

# Marca aristas por pares (para DFS/Dijkstra/MST/Flujo)
func _marcar_aristas_por_par(pars: Array, estado: String) -> void:
	for p in pars:
		for e in grafo_visual.edges:
			if (e["a"] == p[0] and e["b"] == p[1]) or (e["a"] == p[1] and e["b"] == p[0]):
				e["state"] = estado
	grafo_visual.queue_redraw()
	
# ============================================================
# HELPER: CONVIERTE CAMINO DE NODOS A ARISTAS
# ============================================================
func _convert_node_path_to_edge_path(node_path: Array) -> Array:
	var edge_path: Array = []
	if node_path.size() < 2:
		return edge_path

	# Iterar sobre pares de nodos
	for i in range(node_path.size() - 1):
		var u_idx: int = node_path[i]
		var v_idx: int = node_path[i+1]
		
		# Buscar el índice de la arista (u_idx, v_idx)
		var edge_index = -1
		for j in range(grafo_visual.edges.size()):
			var edge = grafo_visual.edges[j]
			
			# Grafo no dirigido: el orden (a, b) o (b, a) es válido.
			var condition_1 = edge.a == u_idx and edge.b == v_idx
			var condition_2 = edge.b == u_idx and edge.a == v_idx
			
			if condition_1 or condition_2:
				edge_index = j
				break
		
		if edge_index != -1:
			edge_path.append(edge_index)
		else:
			# Si la arista no se encuentra, el camino es incorrecto
			return [] 
	return edge_path

func _find_s_set(capacity: Array, flow: Array, s: int) -> Array:
	var n: int = capacity.size()
	var s_set: Array = []
	var visited: Array = []

	# Usaremos BFS en el grafo residual
	var q: Array = [s]
	visited.append(s)
	s_set.append(s)

	while q.size() > 0:
		var u: int = q.pop_front()
		
		for v in range(n):
			# La arista residual (u -> v) tiene capacidad > 0 (Capacidad - Flujo > 0)
			var residual: float = capacity[u][v] - flow[u][v]
			if residual > 0.0 and not (v in visited):
				visited.append(v)
				s_set.append(v)
				q.append(v)
	
	return s_set

func _dijkstra_shortest_path(start_idx: int, end_idx: int) -> Array:
	var nodes: Array[Nodo] = grafo.lista_adyacencia
	var distances: Dictionary = {} 
	var predecessors: Dictionary = {}
	var unvisited: Array = []

	# 1. Inicialización
	for i in range(nodes.size()):
		distances[i] = INF
		predecessors[i] = -1
		unvisited.append(i)
	
	distances[start_idx] = 0

	# 2. Bucle principal
	while not unvisited.is_empty():
		# Encontrar el nodo no visitado con la distancia mínima
		var min_dist: float = INF
		var current_idx: int = -1
		
		for idx in unvisited:
			if distances[idx] < min_dist:
				min_dist = distances[idx]
				current_idx = idx

		if current_idx == -1: break 

		unvisited.erase(current_idx)
		
		if current_idx == end_idx: break 

		# 3. Relajación de Aristas
		var current_node: Nodo = nodes[current_idx]
		
		# Usamos casting para iterar los vecinos de forma segura
		var neighbors = current_node.adyacente.keys() as Array[Nodo] 
		
		for neighbor_node in neighbors:
			var neighbor_idx: int = nodes.find(neighbor_node)
			var weight: float = current_node.adyacente[neighbor_node]
			
			var new_dist: float = distances[current_idx] + weight
			
			if new_dist < distances[neighbor_idx]:
				distances[neighbor_idx] = new_dist
				predecessors[neighbor_idx] = current_idx 

	# 4. Reconstrucción del Camino
	var path: Array = []
	var current: int = end_idx
	
	if distances[end_idx] != INF: 
		while current != -1:
			path.append(current)
			current = predecessors[current]
		path.reverse()
	
	return path

func _set_edge_states_by_index(edge_indices: Array, state: String) -> void:
	for i in range(grafo_visual.edges.size()):
		if i in edge_indices:
			# CORRECCIÓN: Usar ["state"] para acceder a la clave del diccionario
			grafo_visual.edges[i]["state"] = state
		else:
			# Limpiar el estado de las aristas no seleccionadas para evitar residuos visuales
			# CORRECCIÓN: Usar ["state"] para acceder a la clave del diccionario
			grafo_visual.edges[i]["state"] = "" 
	grafo_visual.queue_redraw()

class UnionFind:
	# El array 'parent' almacena el padre de cada elemento.
	var parent: Array
	# El array 'rank' ayuda a mantener el árbol plano (optimización).
	var rank: Array

	func _init(n: int):
		parent.resize(n)
		rank.resize(n)
		for i in range(n):
			parent[i] = i # Inicialmente, cada elemento es su propio padre
			rank[i] = 0

	# Encuentra el representante (raíz) del conjunto que contiene 'i'
	func find(i: int) -> int:
		if parent[i] == i:
			return i
		# Compresión de Ruta (Path compression): Conecta el nodo directamente a la raíz
		parent[i] = find(parent[i])
		return parent[i]

	# Une los conjuntos que contienen 'i' y 'j'
	# Retorna 'true' si la unión fue exitosa (no formó ciclo), 'false' si ya estaban unidos
	func union_sets(i: int, j: int) -> bool:
		var root_i: int = find(i)
		var root_j: int = find(j)

		if root_i != root_j:
			# Unión por Rango (Union by rank): Adjunta el árbol más pequeño al más grande
			if rank[root_i] < rank[root_j]:
				parent[root_i] = root_j
			elif rank[root_i] > rank[root_j]:
				parent[root_j] = root_i
			else:
				parent[root_j] = root_i
				rank[root_i] += 1
			return true # No hubo ciclo
		return false # Ya estaban en el mismo conjunto (hubo ciclo)

# ============================================================
# ETAPA 1 – DFS (verificacion)
# ============================================================
func ejecutar_etapa_recorrido() -> void:
	var player_order: Array = grafo_visual.get_selected()
	var nodos_totales: int = grafo.lista_adyacencia.size()
	
	# 1. Validación de Pre-condición: Mínimo dos nodos seleccionados
	if player_order.size() < 2:
		if algo_label:
			algo_label.text = "⚠️ **ALERTA DE NEMESIS:** Debes seleccionar una secuencia de al menos dos nodos para empezar la ruta."
		return

	var success: bool = true
	var nodos_visitados: Dictionary = {}
	
	# 2. VALIDACIÓN DE ADYACENCIA SECUENCIAL (Chequeo de Regla N°1)
	for i in range(player_order.size()):
		var actual_idx: int = player_order[i]
		var actual_nodo: Nodo = grafo.lista_adyacencia[actual_idx]
		
		# Marcar nodo como visitado (para la validación de duplicados al final)
		nodos_visitados[actual_idx] = true

		if i > 0:
			var anterior_idx: int = player_order[i - 1]
			var anterior_nodo: Nodo = grafo.lista_adyacencia[anterior_idx]
			
			# Regla de Adyacencia: El nodo actual debe ser vecino del nodo anterior
			# Comprobamos si 'anterior_nodo' tiene a 'actual_nodo' en su lista de adyacencia
			if not anterior_nodo.adyacente.has(actual_nodo):
				success = false
				if algo_label:
					# Mensaje específico de fallo
					algo_label.text = "❌ **FALLO DE RUTA:** ¡Error de conexión en tu secuencia! El nodo **%d** no está conectado directamente al nodo **%d**. Vuelve a intentarlo." % [anterior_idx, actual_idx]
				break
	
	# Si la validación de adyacencia falló, terminamos aquí.
	if not success:
		# Limpiar la selección y terminar
		grafo_visual.selected.clear()
		grafo_visual.queue_redraw()
		return
		
	# 3. VALIDACIÓN DE COMPLETITUD (Chequeo de Regla N°2)
	if nodos_visitados.size() != nodos_totales:
		success = false
		if algo_label:
			algo_label.text = "❌ **FALLO DE COBERTURA:** ¡Ruta incompleta! Solo visitaste **%d de %d nodos**. Debes encontrar un camino que toque a todos." % [nodos_visitados.size(), nodos_totales]
	
	# 4. Proporcionar Feedback y Controlar el Avance
	if success:
		# Tarea CORRECTA
		grafo_visual.highlight_nodes_in_order(player_order, "path") # Usamos "path" para la visualización
		
		if algo_label:
			# Mensaje de FELICITACIÓN
			algo_label.text = "✅ **¡CONECTIVIDAD TOTAL!** Has trazado una ruta que toca cada nodo. Etapa 1 superada con éxito."
		
		# Permite el avance
		_set_stage(2) 
		
	else:
		# Tarea INCORRECTA (Si falló el check de completitud)
		# La limpieza ya se hizo si falló Adyacencia. Si falla Completitud, mostramos el mensaje de error.
		if algo_label and not algo_label.text.begins_with("❌ **FALLO DE RUTA:"):
			grafo_visual.selected.clear()
			grafo_visual.queue_redraw()

func _dfs_indice(idx: int, visitado: Array, orden: Array) -> void:
	if idx in visitado: return
	visitado.append(idx)
	orden.append(idx)
	var nodo = grafo.lista_adyacencia[idx]
	for vecino in nodo.adyacente.keys():
		var v_idx: int = grafo.lista_adyacencia.find(vecino)
		if v_idx != -1:
			_dfs_indice(v_idx, visitado, orden)

# ============================================================
# ETAPA 2 – DIJKSTRA
# ============================================================
func ejecutar_etapa_camino_minimo() -> void:
	var sel: Array = grafo_visual.get_selected()
	if sel.size() < 2:
		if algo_label:
			algo_label.text = "Selecciona ORIGEN y DESTINO."
		return
	var origen: int = sel[0]
	var destino: int = sel[1]
	var camino: Array = _dijkstra(origen, destino)
	if camino.size() == 0:
		if algo_label:
			algo_label.text = "No existe camino entre los nodos elegidos."
		return
	var pares: Array = []
	for i in range(camino.size() - 1):
		pares.append([camino[i], camino[i + 1]])
	_marcar_aristas_por_par(pares, "path")
	_set_stage(3) # pasar a MST

func _dijkstra(origen: int, destino: int) -> Array:
	var n: int = grafo.lista_adyacencia.size()
	var dist := []
	var prev := []
	for i in range(n):
		dist.append(INF)
		prev.append(-1)
	dist[origen] = 0.0
	var Q := []
	for i in range(n):
		Q.append(i)
	while Q.size() > 0:
		# En Godot 4, el comparador debe devolver bool
		Q.sort_custom(func(a, b): return dist[a] < dist[b])
		var u: int = Q.pop_front()
		if u == destino: break
		var nodo_u = grafo.lista_adyacencia[u]
		for vecino in nodo_u.adyacente.keys():
			var v: int = grafo.lista_adyacencia.find(vecino)
			if v == -1: continue
			var peso: float = float(nodo_u.adyacente[vecino])
			var alt: float = dist[u] + peso
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
	var camino: Array = []
	if prev[destino] == -1 and destino != origen:
		return camino
	var actual: int = destino
	while actual != -1:
		camino.insert(0, actual)
		actual = prev[actual]
	return camino

# ============================================================
# ETAPA 3 – MST (Prim)
# ============================================================
func ejecutar_etapa_mst() -> void:
	var nodes_count: int = grafo.lista_adyacencia.size()
	# Aristas seleccionadas por el jugador
	var player_selected_edges: Array = grafo_visual.get_selected_edges()

	# 1. Validación de Pre-condición: Al menos una arista seleccionada
	if player_selected_edges.is_empty():
		if algo_label:
			algo_label.text = "⚠️ **ALERTA:** Debes seleccionar las aristas que forman el Árbol de Expansión Mínima (MST)."
		return
	
	# 2. Calcular el MST correcto (usando Kruskal)
	var correct_mst_edges: Array = _kruskal_minimum_spanning_tree()
	
	var success: bool = true

	# 3. Validación de Tamaño (Debe ser N-1 aristas, a menos que el grafo no sea conexo)
	var expected_size: int = nodes_count - 1
	
	if player_selected_edges.size() != expected_size:
		success = false
		if algo_label:
			# Damos un mensaje claro sobre la regla N-1
			algo_label.text = "❌ **FALLO DE TAMAÑO:** El MST debe tener **%d aristas** (N-1), pero seleccionaste **%d**." % [expected_size, player_selected_edges.size()]

	# 4. Validación de Contenido (Set Match)
	if success:
		# Comprueba que todas las aristas seleccionadas por el jugador estén en el MST correcto
		for edge_idx in player_selected_edges:
			if not correct_mst_edges.has(edge_idx):
				success = false
				break
		
		# Si la coincidencia de contenido falló
		if not success:
			if algo_label:
				algo_label.text = "❌ **FALLO DE CONJUNTO:** El conjunto de aristas seleccionado no es el MST correcto. Revisa los pesos y la regla de no formar ciclos."

	# 5. Proporcionar Feedback y Controlar el Avance
	if success:
		# Resaltar las aristas con el nuevo estado "mst" (o "path" si lo prefieres)
		_set_edge_states_by_index(player_selected_edges, "mst")
		if algo_label:
			algo_label.text = "✅ **¡MST ÓPTIMO!** Has seleccionado correctamente el Árbol de Expansión Mínima. Etapa 3 superada."
		
		# Limpiar selecciones
		grafo_visual.selected.clear()
		grafo_visual.selected_edges.clear()
		grafo_visual.queue_redraw()
		_set_stage(4) # Avanzar a Flujo Máximo
		
	else:
		# Fallo: Limpiar la selección y permitir reintento
		grafo_visual.selected.clear()
		grafo_visual.selected_edges.clear()
		grafo_visual.queue_redraw()

func _kruskal_minimum_spanning_tree() -> Array:
	var nodes_count: int = grafo.lista_adyacencia.size()
	if nodes_count == 0: return []

	var all_edges: Array = []
	var mst_edge_indices: Array = []
	
	# 1. Crear una lista plana de TODAS las aristas con su índice original
	for i in range(grafo_visual.edges.size()):
		var e = grafo_visual.edges[i]
		# Kruskal necesita el peso, el índice de la arista, y los nodos extremos (a, b)
		all_edges.append({
			"weight": e["weight"],
			"a": e["a"],
			"b": e["b"],
			"index": i # Guardamos el índice original para la validación
		})
		
	# 2. Ordenar todas las aristas por peso de forma ascendente
	# Usamos sort_custom para ordenar diccionarios
	all_edges.sort_custom(func(a, b): return a.weight < b.weight)

	# 3. Inicializar Union-Find
	var uf: UnionFind = UnionFind.new(nodes_count)
	
	# 4. Iterar sobre aristas ordenadas (greedy approach)
	for edge_data in all_edges:
		var u: int = edge_data.a
		var v: int = edge_data.b
		
		# Intentar unir los conjuntos de U y V
		if uf.union_sets(u, v):
			# La unión fue exitosa (no formó ciclo), la arista es parte del MST
			mst_edge_indices.append(edge_data.index)
			
			# Condición de parada: hemos encontrado N-1 aristas
			if mst_edge_indices.size() == nodes_count - 1:
				break

	return mst_edge_indices

# ============================================================
# ETAPA 4 – FLUJO MÁXIMO (Edmonds–Karp)
# ============================================================
func ejecutar_etapa_flujo() -> void:
	# La selección del usuario son los nodos [Fuente, Sumidero, Nodos del Conjunto S...]
	var player_selected_nodes: Array = grafo_visual.get_selected()
	var nodes_count: int = grafo.lista_adyacencia.size()
	
	# 1. Validación de Pre-condición: Mínimo 2 nodos (S y T)
	if player_selected_nodes.size() < 2:
		if algo_label:
			algo_label.text = "⚠️ **ALERTA:** Selecciona la FUENTE (s), el SUMIDERO (t) y **todos los nodos del Conjunto S** del corte mínimo."
		return

	var s: int = player_selected_nodes[0] # Fuente (S)
	var t: int = player_selected_nodes[1] # Sumidero (T)
	
	# 2. Correr Edmonds-Karp para encontrar el Max Flow
	var capacity := _build_capacity_from_list()
	var result := _edmonds_karp(capacity, s, t)
	var flow = result[0]
	var maxflow: float = result[1]
	
	# 3. Calcular el conjunto S (corte mínimo) correcto
	var correct_s_set: Array = _find_s_set(capacity, flow, s)
	
	# 🟢 DEBUG: Imprimir la respuesta correcta en consola
	print("\n--- Respuesta de la Etapa 4 ---")
	print("Fuente (S): %d, Sumidero (T): %d" % [s, t])
	print("Flujo Máximo (Max Flow): %s" % str(maxflow))
	print("Conjunto S Correcto (Corte Mínimo): %s" % str(correct_s_set))
	print("---------------------------------\n")
	
	# 4. Preparar el Conjunto S Propuesto por el Jugador (CORRECCIÓN CLAVE)
	var player_s_set_proposed: Array = player_selected_nodes.duplicate()
	
	# ⚠️ CORRECCIÓN: Eliminamos el Sumidero (T) de la selección del jugador
	# para compararlo con el Conjunto S correcto (que no incluye a T).
	if player_s_set_proposed.has(t):
		player_s_set_proposed.erase(t)
		
	var success: bool = true

	# 5. VALIDACIÓN: Coincidencia de contenido y tamaño
	
	# La selección del jugador (sin T) debe tener el mismo tamaño que el S-Set correcto
	if player_s_set_proposed.size() != correct_s_set.size():
		success = false
	
	# Si el tamaño coincide, comprobamos el contenido
	if success:
		# Ordenamos los arrays para asegurar que la comparación de contenido sea exacta
		player_s_set_proposed.sort()
		correct_s_set.sort()
		
		# Comprobamos que todos los elementos coincidan
		if player_s_set_proposed != correct_s_set:
			success = false
	
	# 6. Proporcionar Feedback y Controlar el Avance
	if success:
		# Visualización de aristas que llevan flujo y aristas saturadas
		var pares_flow := []
		var pares_sat := []
		var n: int = capacity.size()

		for i in range(n):
			for j in range(i + 1, n):
				if capacity[i][j] > 0 or capacity[j][i] > 0:
					var f: float = flow[i][j]
					
					if f > 0.0:
						pares_flow.append([i, j])
					
					# Saturación: se satura si la capacidad residual es cero
					if capacity[i][j] > 0.0 and f >= capacity[i][j]:
						pares_sat.append([i, j])

		_marcar_aristas_por_par(pares_flow, "flow_used")
		_marcar_aristas_por_par(pares_sat, "saturated")
		
		# Resaltar el Conjunto S (nodos seleccionados)
		grafo_visual.highlight_nodes_in_order(player_s_set_proposed, "cut_set")
		
		_set_stage(5)
		if algo_label:
			algo_label.text = "✅ **¡FLUJO MÁXIMO!** Has identificado correctamente el Conjunto S \n (S-Set). Flujo máximo: %s. ¡Misión final completada!" % str(maxflow)
		
	else:
		# Fallo: Limpiar la selección y permitir reintento
		if algo_label:
			algo_label.text = "❌ **FALLO EN EL CORTE:** El conjunto de nodos seleccionado no corresponde al \n Conjunto S del Corte Mínimo. Revisa el grafo residual y los caminos."
		
		grafo_visual.selected.clear()
		grafo_visual.queue_redraw()

func _build_capacity_from_list() -> Array:
	var n: int = grafo.lista_adyacencia.size()
	var cap := []
	for i in range(n):
		cap.append([])
		for _j in range(n):
			cap[i].append(0.0)
	
	for i in range(n):
		var u = grafo.lista_adyacencia[i]
		for vecino in u.adyacente.keys():
			var j: int = grafo.lista_adyacencia.find(vecino)
			if j == -1: continue
			
			var weight = float(u.adyacente[vecino])
			
			# 🟢 CORRECCIÓN CLAVE: Capacidad Bidireccional
			# Asumimos que el peso en la arista representa la capacidad
			# en ambas direcciones (i -> j) y (j -> i).
			cap[i][j] = weight
			cap[j][i] = weight
			
	return cap

func _edmonds_karp(capacity: Array, s: int, t: int) -> Array:
	var n: int = capacity.size()
	var flow := []
	for i in range(n):
		flow.append([])
		for j in range(n):
			flow[i].append(0.0)
			
	var maxflow: float = 0.0
	
	while true:
		var parent := []
		for i in range(n): parent.append(-1)
		var q := []
		q.append(s)
		parent[s] = -2
		
		var path_cap := []
		for i in range(n): path_cap.append(0.0)
		path_cap[s] = INF # Usar la constante definida
		
		var found: bool = false
		
		while q.size() > 0 and not found:
			var u: int = q.pop_front()
			for v in range(n):
				var residual: float = capacity[u][v] - flow[u][v]
				
				if residual > 0.0 and parent[v] == -1:
					parent[v] = u
					# Corregir la asignación de path_cap para evitar INF si ya hay un valor
					path_cap[v] = min(path_cap[u], residual) 
					
					if v == t:
						found = true
						break
					q.append(v)
		
		if not found: break
		
		var increment: float = path_cap[t]
		var v2: int = t
		while v2 != s:
			var u2: int = parent[v2]
			flow[u2][v2] += increment
			flow[v2][u2] -= increment
			v2 = u2
			
		maxflow += increment
		
	return [flow, maxflow]

# ============================================================
# Texto del Label según la etapa / helper
# ============================================================
func _set_stage(n:int) -> void:
	etapa_mision_final = n
	if algo_label:
		algo_label.text = _texto_etapa(n)
	if siguiente_button:
		siguiente_button.disabled = (n < 5)
	if vida_nemesis_display and not vida_nemesis_texturas.is_empty():
		# La etapa 1 corresponde al índice 0, la etapa 2 al índice 1, etc.
		var texture_index: int = clamp(n - 1, 0, vida_nemesis_texturas.size() - 1)
		vida_nemesis_display.texture = vida_nemesis_texturas[texture_index]
		
	if nemesis and not NEMESIS_texturas.is_empty():
		# La etapa 1 corresponde al índice 0, la etapa 2 al índice 1, etc.
		var texture_index2: int = clamp(n - 1, 0, NEMESIS_texturas.size() - 1)
		nemesis.texture = NEMESIS_texturas[texture_index2]

func _texto_etapa(n:int) -> String:
	match n:
		1:
			return "Haz llegado al nivel final, vas a enfrentarte con NEMESIS ¿estas preparado?. \n Etapa 1: Recorrido (DFS) \n Oprime el boton generar grafo para iniciar. Selecciona un nodo y presiona Verificar."

		2:
			return "Exelente hemos podido hacerle daño a NEMESIS, pero no es suficiente continua. \n Etapa 2: Camino mínimo (Dijkstra) \n Selecciona ORIGEN y DESTINO; luego Verificar."

		3:
			return "Brutal sigue asi ya vas por la mitad de su vida, no pares. \n Etapa 3: Árbol de Expansión Mínima (Prim) \n Presiona Verificar para construir el AEM."

		4:
			return "Ya te falta poco un golpe mas y se acabo. \n Etapa 4: Flujo Máximo (Edmonds–Karp) \n Selecciona FUENTE y SUMIDERO; luego Verificar."

		5:
			return "¡¡¡FELICIDADES!!! haz acabado con NEMESIS gracias a tu ayuda nos deshicimos de el. Hasta la proxima compañero cibernetico \n ¡Misión final completada!"
		_: # 👈 COMODÍN: Asegura que siempre haya un retorno
			return "Etapa no definida: " + str(n)

# ============================================================
# LÓGICA DEL BOTÓN SIGUIENTE
# ============================================================
func _on_siguiente_button_pressed() -> void:
	# La Etapa 4 es la penúltima. La Etapa 5 es la final/completada.
	if etapa_mision_final >= 4:
		# Si la Etapa 4 (Flujo Máximo) ha sido pasada y el usuario presiona "Verificar" (que llama a _set_stage(5))
		# o si el usuario presiona "Siguiente"
		
		# Forzamos el mensaje de la Etapa 5 (final)
		_set_stage(5) 
		# Si ya estamos en la Etapa 5 (misión completada), podríamos deshabilitar el botón
		if etapa_mision_final == 5:
			siguiente_button.disabled = true
