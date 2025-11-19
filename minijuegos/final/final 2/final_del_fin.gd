extends Node2D

@onready var grafo_visual: Node2D = $CanvasLayer/Node2D
@onready var Grafo = preload("res://core/Grafo.gd")
@onready var Nodo = preload("res://core/Nodo.gd")

var grafo
var etapa_mision_final: int = 1
var pantalla_ancho := 1152
var pantalla_alto := 648

func _ready() -> void:
	randomize()
	grafo = Grafo.new()
	# no añadimos grafo como child porque tu Grafo es una estructura; si lo necesitas en el árbol puedes add_child(grafo)

# Botón "Generar Grafo"
func _on_generar_grafo_button_down() -> void:
	etapa_mision_final = 1
	generar_grafo_conexo_aleatorio()
	mostrar_grafo()
	grafo_visual.queue_redraw()

# Botón "Verificar" avanza una etapa de la misión final
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
		_:
			print("Misión final completada.")

# ---------------------------
# Generación del grafo (5 vértices, conexo)
# ---------------------------
func generar_grafo_conexo_aleatorio() -> void:
	grafo.lista_adyacencia.clear()
	grafo.matriz_adyacencia.clear()
	Nodo.cid = 0

	var total := 5
	var nodos_creados: Array = []
	for i in range(total):
		var n = Nodo.new("N" + str(i))
		grafo.agregar_nodo(n)
		nodos_creados.append(n)

	# crear árbol aleatorio (garantiza conexion)
	var conectados: Array = [ nodos_creados.pop_back() ]
	while nodos_creados.size() > 0:
		var nuevo = nodos_creados.pop_back()
		var existente = conectados[randi() % conectados.size()]
		var peso = randi() % 99 + 1
		grafo.conectar_nodo(existente, nuevo, peso)
		conectados.append(nuevo)

	# añadir 0-2 aristas extra
	var extras = randi() % 3
	for i in range(extras):
		var a = grafo.lista_adyacencia[randi() % total]
		var b = grafo.lista_adyacencia[randi() % total]
		if a == b: continue
		if b in a.adyacente: continue
		var peso = randi() % 99 + 1
		grafo.conectar_nodo(a, b, peso)

# ---------------------------
# Construir posiciones y lista de aristas (con estados) y pasar al visual
# ---------------------------
func mostrar_grafo() -> void:
	var posiciones: Array = []
	var aristas: Array = []

	var total := grafo.lista_adyacencia.size()
	if total == 0:
		return

	# Zona segura (no cubrir label arriba ni botones abajo)
	var margen_superior := 70
	var margen_inferior := 120
	var x_min := 120
	var x_max := pantalla_ancho - 120
	var y_min := margen_superior + 40
	var y_max := pantalla_alto - margen_inferior - 40

	var centro := Vector2((x_min + x_max) / 2.0, (y_min + y_max) / 2.0)
	var radio_x := (x_max - x_min) / 2.0
	var radio_y := (y_max - y_min) / 2.0

	var angulo: float = 0.0
	var inc: float = TAU / float(total)

	for n in grafo.lista_adyacencia:
		var pos := centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y)
		posiciones.append(pos)
		angulo += inc

	# Construir aristas únicas (a < b) con peso y estado inicial
	for i in range(total):
		var nodo = grafo.lista_adyacencia[i]
		for vecino in nodo.adyacente.keys():
			var j := grafo.lista_adyacencia.find(vecino)
			if j == -1: continue
			if i < j:
				var peso := float(nodo.adyacente[vecino])
				aristas.append({
					"a": i,
					"b": j,
					"weight": peso,
					"state": "normal"   # estados: normal, visited, path, mst, flow_used, saturated
				})

	grafo_visual.set_graph(posiciones, aristas)

# ---------------------------
# UTIL: Obtener lista de aristas indexadas (para colorear)
# ---------------------------
func _marcar_aristas_por_par(pars: Array, estado: String) -> void:
	# pars: array de [a,b] pares (ambos ints)
	for p in pars:
		for e in grafo_visual.edges:
			if (e["a"] == p[0] and e["b"] == p[1]) or (e["a"] == p[1] and e["b"] == p[0]):
				e["state"] = estado
	grafo_visual.queue_redraw()

# ---------------------------
# ETAPA 1: Recorrido (DFS) — requiere 1 nodo seleccionado (inicio)
# ---------------------------
func ejecutar_etapa_recorrido() -> void:
	var sel := grafo_visual.get_selected()
	if sel.size() == 0:
		print("Selecciona un nodo para iniciar el recorrido (clic).")
		return

	var start_idx := sel[0]
	# hacer DFS en índices
	var orden := []
	var visitado := []
	_dfs_indice(start_idx, visitado, orden)

	# marcar nodos visitados (grafo_visual.selected -> lista de índices para colorear)
	grafo_visual.highlight_nodes_in_order(orden, "visited")
	print("Recorrido DFS:", orden)

	# pasar a etapa siguiente
	etapa_mision_final = 2

# DFS (por índices)
func _dfs_indice(idx: int, visitado: Array, orden: Array) -> void:
	if idx in visitado:
		return
	visitado.append(idx)
	orden.append(idx)
	var nodo = grafo.lista_adyacencia[idx]
	for vecino in nodo.adyacente.keys():
		var v_idx := grafo.lista_adyacencia.find(vecino)
		if v_idx != -1:
			_dfs_indice(v_idx, visitado, orden)

# ---------------------------
# ETAPA 2: Camino mínimo (Dijkstra) — requiere 2 nodos seleccionados (origen, destino)
# ---------------------------
func ejecutar_etapa_camino_minimo() -> void:
	var sel := grafo_visual.get_selected()
	if sel.size() < 2:
		print("Selecciona ORIGEN y DESTINO (dos nodos).")
		return
	var origen := sel[0]
	var destino := sel[1]

	var camino := _dijkstra(origen, destino)
	if camino.size() == 0:
		print("No existe camino entre", origen, "y", destino)
		return

	# marcar aristas que forman el camino
	var pares := []
	for i in range(camino.size()-1):
		pares.append([camino[i], camino[i+1]])
	_marcar_aristas_por_par(pares, "path")
	print("Camino mínimo:", camino)

	etapa_mision_final = 3

# Dijkstra sobre índices (usa grafo.lista_adyacencia y Nodo.adyacente)
func _dijkstra(origen: int, destino: int) -> Array:
	var n := grafo.lista_adyacencia.size()
	var dist = []
	var prev = []
	for i in range(n):
		dist.append(INF)
		prev.append(-1)

	dist[origen] = 0.0
	var Q := []
	for i in range(n):
		Q.append(i)

	while Q.size() > 0:
		# seleccionar u en Q con dist mínima
		Q.sort_custom(func(a, b):
			if dist[a] < dist[b]:
				return -1
			if dist[a] > dist[b]:
				return 1
			return 0
		)
		var u := Q.pop_front()
		if u == destino:
			break
		var nodo_u := grafo.lista_adyacencia[u]
		for vecino in nodo_u.adyacente.keys():
			var v := grafo.lista_adyacencia.find(vecino)
			if v == -1: continue
			var peso := float(nodo_u.adyacente[vecino])
			var alt := dist[u] + peso
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u

	# reconstruir camino
	var camino := []
	if prev[destino] == -1 and destino != origen:
		# si no conectado
		if destino != origen and dist[destino] == INF:
			return camino
	var u2 := destino
	while u2 != -1:
		camino.insert(0, u2)
		u2 = prev[u2]
	return camino

# ---------------------------
# ETAPA 3: MST (Prim) — no requiere selección
# ---------------------------
func ejecutar_etapa_mst() -> void:
	var n := grafo.lista_adyacencia.size()
	if n == 0:
		return
	var visitado := [0]  # empezar en 0
	var aristas_mst := []

	while visitado.size() < n:
		var mejor_peso := INF
		var mejor_par := null
		for u in visitado:
			var nodo_u := grafo.lista_adyacencia[u]
			for vecino in nodo_u.adyacente.keys():
				var v := grafo.lista_adyacencia.find(vecino)
				if v == -1: continue
				var peso := float(nodo_u.adyacente[vecino])
				if v in visitado: continue
				if peso < mejor_peso:
					mejor_peso = peso
					mejor_par = [u, v]
		if mejor_par == null:
			break
		visitado.append(mejor_par[1])
		aristas_mst.append(mejor_par)

	# marcar MST
	_marcar_aristas_por_par(aristas_mst, "mst")
	print("MST edges:", aristas_mst)
	etapa_mision_final = 4

# ---------------------------
# ETAPA 4: Flujo Máximo (Edmonds-Karp)
# requiere seleccionar 2 nodos: fuente y sumidero
# ---------------------------
func ejecutar_etapa_flujo() -> void:
	var sel := grafo_visual.get_selected()
	if sel.size() < 2:
		print("Selecciona FUENTE y SUMIDERO (dos nodos).")
		return
	var s := sel[0]
	var t := sel[1]

	var n := grafo.lista_adyacencia.size()
	# construir matriz de capacidades desde grafo.matriz_adyacencia (asumimos contiene pesos)
	var capacity := []
	for i in range(n):
		capacity.append([])
		for j in range(n):
			var val := 0.0
			if i < grafo.matriz_adyacencia.size() and j < grafo.matriz_adyacencia[i].size():
				val = float(grafo.matriz_adyacencia[i][j])
			capacity[i].append(val)

	var resultado := _edmonds_karp(capacity, s, t)
	var flow = resultado[0]
var maxflow = resultado[1]
	print("Flujo máximo:", maxflow)

	# flow es matriz de flujos; marcar aristas con flow>0 como flow_used, saturadas donde flow==capacity
	var pares_flow := []
	var pares_saturated := []
	for i in range(n):
		for j in range(i+1, n):
			if capacity[i][j] > 0 or capacity[j][i] > 0:
				var f := flow[i][j] if flow[i][j] != null else 0.0
				if f > 0:
					pares_flow.append([i, j])
				if f >= capacity[i][j] and capacity[i][j] > 0:
					pares_saturated.append([i, j])

	_marcar_aristas_por_par(pares_flow, "flow_used")
	_marcar_aristas_por_par(pares_saturated, "saturated")

	etapa_mision_final = 5
	print("Misión final completada.")

# Edmonds-Karp (retorna flow matrix y maxflow)
func _edmonds_karp(capacity: Array, s: int, t: int) -> Array:
	var n := capacity.size()
	# inicializar flow 0
	var flow := []
	for i in range(n):
		flow.append([])
		for j in range(n):
			flow[i].append(0.0)

	var maxflow := 0.0
	while true:
		# BFS para encontrar camino aumentante
		var parent := []
		for i in range(n):
			parent.append(-1)
		var q := []
		q.append(s)
		parent[s] = -2  # marca origen
		var path_cap := []
		for i in range(n): path_cap.append(0.0)
		path_cap[s] = INF

		var found := false
		while q.size() > 0 and not found:
			var u := q.pop_front()
			for v in range(n):
				# residual capacity = capacity[u][v] - flow[u][v]
				var residual := capacity[u][v] - flow[u][v]
				if residual > 0 and parent[v] == -1:
					parent[v] = u
					path_cap[v] = min(path_cap[u], residual) if path_cap[u] != INF else residual
					if v == t:
						found = true
						break
					q.append(v)
		if not found:
			break
		var increment := path_cap[t]
		# augment along path
		var v := t
		while v != s:
			var u := parent[v]
			flow[u][v] += increment
			flow[v][u] -= increment
			v = u
		maxflow += increment

	return [flow, maxflow]
