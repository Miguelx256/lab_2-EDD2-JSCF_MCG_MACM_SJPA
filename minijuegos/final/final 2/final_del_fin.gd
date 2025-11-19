extends Node2D

@onready var grafo_visual: Node2D = $CanvasLayer/Node2D
@onready var Grafo = preload("res://core/Grafo.gd")
@onready var Nodo = preload("res://core/Nodo.gd")

var grafo
var etapa_mision_final: int = 1
var pantalla_ancho: int = 1152
var pantalla_alto: int = 648

func _ready() -> void:
	randomize()
	grafo = Grafo.new()


# -------------------------------------------------------------------
# BOTÓN: GENERAR GRAFO
# -------------------------------------------------------------------
func _on_generar_grafo_button_down() -> void:
	etapa_mision_final = 1
	generar_grafo_conexo_aleatorio()
	mostrar_grafo()
	grafo_visual.queue_redraw()


# -------------------------------------------------------------------
# BOTÓN: VERIFICAR
# -------------------------------------------------------------------
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


# -------------------------------------------------------------------
# GENERAR GRAFO CONEXO DE 5 NODOS
# -------------------------------------------------------------------
func generar_grafo_conexo_aleatorio() -> void:
	grafo.lista_adyacencia.clear()
	grafo.matriz_adyacencia.clear()
	Nodo.cid = 0

	var total: int = 5
	var nodos_creados: Array = []

	for i in range(total):
		var n: Nodo = Nodo.new("N" + str(i))
		grafo.agregar_nodo(n)
		nodos_creados.append(n)

	var conectados: Array = [nodos_creados.pop_back()]

	while nodos_creados.size() > 0:
		var nuevo = nodos_creados.pop_back()
		var existente = conectados[randi() % conectados.size()]
		var peso: float = float(randi() % 99 + 1)
		grafo.conectar_nodo(existente, nuevo, peso)
		conectados.append(nuevo)

	var extras: int = randi() % 3
	for i in range(extras):
		var a = grafo.lista_adyacencia[randi() % total]
		var b = grafo.lista_adyacencia[randi() % total]
		if a == b: continue
		if b in a.adyacente: continue
		var peso2: float = float(randi() % 99 + 1)
		grafo.conectar_nodo(a, b, peso2)


# -------------------------------------------------------------------
# MOSTRAR GRAFO EN PANTALLA
# -------------------------------------------------------------------
func mostrar_grafo() -> void:
	var posiciones: Array = []
	var aristas: Array = []

	var total: int = grafo.lista_adyacencia.size()
	if total == 0:
		return

	var margen_superior: int = 70
	var margen_inferior: int = 120
	var x_min: int = 120
	var x_max: int = pantalla_ancho - 120
	var y_min: int = margen_superior + 40
	var y_max: int = pantalla_alto - margen_inferior - 40

	var centro := Vector2((x_min + x_max) / 2.0, (y_min + y_max) / 2.0)
	var radio_x: float = (x_max - x_min) / 2.0
	var radio_y: float = (y_max - y_min) / 2.0

	var angulo: float = 0.0
	var inc: float = TAU / float(total)

	for n in grafo.lista_adyacencia:
		var pos := centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y)
		posiciones.append(pos)
		angulo += inc

	for i in range(total):
		var nodo = grafo.lista_adyacencia[i]
		for vecino in nodo.adyacente.keys():
			var j: int = grafo.lista_adyacencia.find(vecino)
			if j == -1: continue
			if i < j:
				var peso: float = float(nodo.adyacente[vecino])
				aristas.append({
					"a": i,
					"b": j,
					"weight": peso,
					"state": "normal"
				})

	grafo_visual.set_graph(posiciones, aristas)


# -------------------------------------------------------------------
# MARCAR ARISTAS POR PARES (CAMINO, MST, FLUJO)
# -------------------------------------------------------------------
func _marcar_aristas_por_par(pars: Array, estado: String) -> void:
	for p in pars:
		for e in grafo_visual.edges:
			if (e["a"] == p[0] and e["b"] == p[1]) or (e["a"] == p[1] and e["b"] == p[0]):
				e["state"] = estado
	grafo_visual.queue_redraw()


# -------------------------------------------------------------------
# ETAPA 1 – DFS
# -------------------------------------------------------------------
func ejecutar_etapa_recorrido() -> void:
	var sel: Array = grafo_visual.get_selected()
	if sel.size() == 0:
		print("Selecciona un nodo para iniciar el recorrido.")
		return

	var start_idx: int = sel[0]
	var orden: Array = []
	var visitado: Array = []
	_dfs_indice(start_idx, visitado, orden)

	grafo_visual.highlight_nodes_in_order(orden, "visited")
	print("DFS:", orden)

	etapa_mision_final = 2


func _dfs_indice(idx: int, visitado: Array, orden: Array) -> void:
	if idx in visitado:
		return
	visitado.append(idx)
	orden.append(idx)

	var nodo = grafo.lista_adyacencia[idx]
	for vecino in nodo.adyacente.keys():
		var v_idx: int = grafo.lista_adyacencia.find(vecino)
		if v_idx != -1:
			_dfs_indice(v_idx, visitado, orden)


# -------------------------------------------------------------------
# ETAPA 2 – DIJKSTRA
# -------------------------------------------------------------------
func ejecutar_etapa_camino_minimo() -> void:
	var sel: Array = grafo_visual.get_selected()
	if sel.size() < 2:
		print("Selecciona ORIGEN y DESTINO.")
		return

	var origen: int = sel[0]
	var destino: int = sel[1]

	var camino: Array = _dijkstra(origen, destino)
	if camino.size() == 0:
		print("No existe camino.")
		return

	var pares: Array = []
	for i in range(camino.size() - 1):
		pares.append([camino[i], camino[i + 1]])

	_marcar_aristas_por_par(pares, "path")
	print("Camino mínimo:", camino)

	etapa_mision_final = 3


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
		Q.sort_custom(func(a, b):
			if dist[a] < dist[b]: return -1
			if dist[a] > dist[b]: return 1
			return 0
		)

		var u: int = Q.pop_front()
		if u == destino:
			break

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


# -------------------------------------------------------------------
# ETAPA 3 – MST PRIM
# -------------------------------------------------------------------
func ejecutar_etapa_mst() -> void:
	var n: int = grafo.lista_adyacencia.size()
	if n == 0:
		return

	var visitado: Array = [0]
	var aristas_mst: Array = []

	while visitado.size() < n:
		var mejor_peso: float = INF
		var mejor_par = null

		for u in visitado:
			var nodo_u = grafo.lista_adyacencia[u]
			for vecino in nodo_u.adyacente.keys():
				var v: int = grafo.lista_adyacencia.find(vecino)
				if v == -1 or v in visitado:
					continue

				var peso: float = float(nodo_u.adyacente[vecino])
				if peso < mejor_peso:
					mejor_peso = peso
					mejor_par = [u, v]

		if mejor_par == null:
			break

		visitado.append(mejor_par[1])
		aristas_mst.append(mejor_par)

	_marcar_aristas_por_par(aristas_mst, "mst")
	print("MST:", aristas_mst)

	etapa_mision_final = 4


# -------------------------------------------------------------------
# ETAPA 4 – FLUJO MÁXIMO (EDMONDS–KARP)
# -------------------------------------------------------------------
func ejecutar_etapa_flujo() -> void:
	var sel: Array = grafo_visual.get_selected()
	if sel.size() < 2:
		print("Selecciona fuente y sumidero.")
		return

	var s: int = sel[0]
	var t: int = sel[1]

	var n: int = grafo.lista_adyacencia.size()
	var capacity := []

	for i in range(n):
		capacity.append([])
		for j in range(n):
			var val: float = 0.0
			if i < grafo.matriz_adyacencia.size() and j < grafo.matriz_adyacencia[i].size():
				val = float(grafo.matriz_adyacencia[i][j])
			capacity[i].append(val)

	var result := _edmonds_karp(capacity, s, t)
	var flow = result[0]
	var maxflow: float = result[1]

	print("Flujo máximo:", maxflow)

	var pares_flow := []
	var pares_sat := []

	for i in range(n):
		for j in range(i + 1, n):
			if capacity[i][j] > 0 or capacity[j][i] > 0:
				var f: float = flow[i][j]
				if f > 0:
					pares_flow.append([i, j])
				if f >= capacity[i][j] and capacity[i][j] > 0:
					pares_sat.append([i, j])

	_marcar_aristas_por_par(pares_flow, "flow_used")
	_marcar_aristas_por_par(pares_sat, "saturated")

	etapa_mision_final = 5
	print("¡Misión Final COMPLETADA!")


# -------------------------------------------------------------------
# EDMONDS–KARP
# -------------------------------------------------------------------
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
		for i in range(n):
			parent.append(-1)

		var q := []
		q.append(s)
		parent[s] = -2

		var path_cap := []
		for i in range(n):
			path_cap.append(0.0)
		path_cap[s] = INF

		var found: bool = false

		while q.size() > 0 and not found:
			var u: int = q.pop_front()

			for v in range(n):
				var residual: float = capacity[u][v] - flow[u][v]
				if residual > 0 and parent[v] == -1:
					parent[v] = u

					if path_cap[u] == INF:
						path_cap[v] = residual
					else:
						path_cap[v] = min(path_cap[u], residual)

					if v == t:
						found = true
						break

					q.append(v)

		if not found:
			break

		var increment: float = path_cap[t]
		var v2: int = t

		while v2 != s:
			var u2: int = parent[v2]
			flow[u2][v2] += increment
			flow[v2][u2] -= increment
			v2 = u2

		maxflow += increment

	return [flow, maxflow]
