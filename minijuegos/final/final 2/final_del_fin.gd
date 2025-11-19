extends Node2D

@onready var grafo_visual: Node2D = $CanvasLayer/Node2D
@onready var Grafo = preload("res://core/Grafo.gd")
@onready var Nodo = preload("res://core/Nodo.gd")
@onready var info_label: Label = $Label   # Nuestro Label de ayuda

var grafo
var etapa_mision_final: int = 1
var pantalla_ancho: int = 1152
var pantalla_alto: int = 648

# ---------------- SISTEMA DE MENSAJES ----------------
var mensajes: Array = []        # Historial de mensajes
var max_mensajes: int = 5       # Máximo de mensajes visibles
var tiempo_mensaje: float = 4.0 # Segundos que cada mensaje permanece

# Mostrar mensaje con tipo: "exito", "instruccion", "error"
func mostrar_mensaje(texto: String, tipo: String = "instruccion") -> void:
	mensajes.append({"texto": texto, "tipo": tipo})
	if mensajes.size() > max_mensajes:
		mensajes.pop_front()
	_actualizar_label()
	quitar_mensaje_despues(texto, tipo, tiempo_mensaje)

# Actualizar el Label con BBCode y colores
func _actualizar_label() -> void:
	# Si el Label aún no está listo, salir (evita el error de null)
	if info_label == null:
		return

	var formatted_text: String = ""
	for m in mensajes:
		var color: Color = Color.WHITE
		match m["tipo"]:
			"exito":
				color = Color.GREEN
			"instruccion":
				color = Color.YELLOW
			"error":
				color = Color.RED
			_:
				color = Color.WHITE

		formatted_text += "[color=#%02X%02X%02X]%s[/color]\n" % [
			int(color.r * 255),
			int(color.g * 255),
			int(color.b * 255),
			m["texto"]
		]

	info_label.bbcode_enabled = true
	info_label.text = formatted_text


# Quitar mensaje automáticamente usando Timer
func quitar_mensaje_despues(texto: String, tipo: String, delay: float) -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(Callable(self, "_on_timer_timeout").bind(texto, tipo, timer))

func _on_timer_timeout(texto: String, tipo: String, timer: Timer) -> void:
	for m in mensajes:
		if m["texto"] == texto and m["tipo"] == tipo:
			mensajes.erase(m)
			_actualizar_label()
			break
	timer.queue_free()
# -----------------------------------------------------

func _ready() -> void:
	randomize()
	grafo = Grafo.new()
	
	# Mensaje inicial de bienvenida
	mostrar_mensaje("¡Bienvenido! Estás en el NIVEL FINAL.", "instruccion")
	mostrar_mensaje("Tu misión: recorrido DFS → camino mínimo → MST → flujo máximo.", "instruccion")

# -------------------------------------------------------------------
# BOTÓN: GENERAR GRAFO
# -------------------------------------------------------------------
func _on_generar_grafo_button_down() -> void:
	etapa_mision_final = 1
	generar_grafo_conexo_aleatorio()
	mostrar_grafo()
	grafo_visual.queue_redraw()
	mostrar_mensaje("Grafo generado correctamente.", "exito")

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
			mostrar_mensaje("¡Misión final completada! 🎉", "exito")

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

	var centro: Vector2 = Vector2((x_min + x_max) / 2.0, (y_min + y_max) / 2.0)
	var radio_x: float = (x_max - x_min) / 2.0
	var radio_y: float = (y_max - y_min) / 2.0

	var angulo: float = 0.0
	var inc: float = TAU / float(total)

	for n in grafo.lista_adyacencia:
		var pos: Vector2 = centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y)
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
# MARCAR ARISTAS POR PARES
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
		mostrar_mensaje("Selecciona un nodo para iniciar el recorrido (DFS).", "error")
		return

	var start_idx: int = sel[0]
	var orden: Array = []
	var visitado: Array = []
	_dfs_indice(start_idx, visitado, orden)

	grafo_visual.highlight_nodes_in_order(orden, "visited")
	etapa_mision_final = 2
	mostrar_mensaje("¡Recorrido DFS completado! ✅", "exito")
	mostrar_mensaje("Selecciona ORIGEN y DESTINO para camino mínimo.", "instruccion")

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
		mostrar_mensaje("Selecciona ORIGEN y DESTINO para calcular el camino mínimo.", "error")
		return

	var origen: int = sel[0]
	var destino: int = sel[1]
	var camino: Array = _dijkstra(origen, destino)
	if camino.size() == 0:
		mostrar_mensaje("No existe camino entre los nodos seleccionados ❌", "error")
		return

	var pares: Array = []
	for i in range(camino.size() - 1):
		pares.append([camino[i], camino[i + 1]])

	_marcar_aristas_por_par(pares, "path")
	mostrar_mensaje("¡Camino mínimo encontrado! Peso total: %d" % _calcular_peso_camino(pares), "exito")
	etapa_mision_final = 3

func _calcular_peso_camino(pares: Array) -> float:
	var total: float = 0.0
	for par in pares:
		var n1 = grafo.lista_adyacencia[par[0]]
		var n2 = grafo.lista_adyacencia[par[1]]
		total += n1.adyacente[n2]
	return total

# -------------------------------------------------------------------
# DIJKSTRA COMPLETO
# -------------------------------------------------------------------
func _dijkstra(origen: int, destino: int) -> Array:
	var total: int = grafo.lista_adyacencia.size()

	var dist: Array = []
	var prev: Array = []
	var visitado: Array = []

	dist.resize(total)
	prev.resize(total)
	visitado.resize(total)

	for i in range(total):
		dist[i] = INF
		prev[i] = -1
		visitado[i] = false

	dist[origen] = 0.0

	for _i in range(total):
		var u: int = -1
		var mejor: float = INF

		for v in range(total):
			if not visitado[v] and dist[v] < mejor:
				mejor = dist[v]
				u = v

		if u == -1:
			break

		visitado[u] = true
		var nodo_u = grafo.lista_adyacencia[u]

		for vecino in nodo_u.adyacente.keys():
			var v: int = grafo.lista_adyacencia.find(vecino)
			if v == -1:
				continue

			var peso: float = float(nodo_u.adyacente[vecino])
			var nueva_dist: float = dist[u] + peso

			if nueva_dist < dist[v]:
				dist[v] = nueva_dist
				prev[v] = u

	# reconstruir camino
	var camino: Array = []
	var actual: int = destino

	while actual != -1:
		camino.append(actual)
		actual = prev[actual]

	camino.reverse()

	if camino.size() == 1 and camino[0] != origen:
		return []  # no existe camino

	return camino

# -------------------------------------------------------------------
# ETAPA 3 – MST (placeholder)
# -------------------------------------------------------------------
func ejecutar_etapa_mst() -> void:
	mostrar_mensaje("Etapa MST aún no implementada.", "instruccion")
	etapa_mision_final = 4

# -------------------------------------------------------------------
# ETAPA 4 – FLUJO (placeholder)
# -------------------------------------------------------------------
func ejecutar_etapa_flujo() -> void:
	mostrar_mensaje("Etapa de flujo máximo aún no implementada.", "instruccion")
	etapa_mision_final = 5
