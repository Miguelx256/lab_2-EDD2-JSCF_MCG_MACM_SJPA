extends Node2D

var nodes: Array = []     # posiciones: Vector2
var edges: Array = []     # array de diccionarios: {a:int, b:int, weight:float, state:String}
var selected: Array = []  # índices seleccionados por el jugador (ints)
var radius := 22
var font := null

func _ready() -> void:
	# opcional: asignar fuente si existe, sino draw_string usa fuente por defecto
	font = ThemeDB.fallback_font

# API usada por Main
func set_graph(p_nodes: Array, p_edges: Array) -> void:
	nodes = p_nodes.duplicate()
	edges = []
	for e in p_edges:
		# asegurarse copia limpia
		edges.append({
			"a": int(e["a"]),
			"b": int(e["b"]),
			"weight": float(e["weight"]),
			"state": str(e["state"])
		})
	selected.clear()
	queue_redraw()

func get_selected() -> Array:
	return selected.duplicate()

# Permite al Main pedir que se coloreen nodos en orden (animación simple: establecer selected = orden)
# tipo puede ser "visited" o catálogo propio; aquí solo usamos seleccion como indicador visual
func highlight_nodes_in_order(order: Array, tipo: String="visited") -> void:
	# para simplicidad, establecemos selected como la lista de índices visitados
	selected = order.duplicate()
	queue_redraw()

# Exponer edges para que el main pueda modificarlas directamente
func _get_edges_reference() -> Array:
	return edges

# Dibujo
func _draw() -> void:
	# dibujar aristas
	for e in edges:
		var a := e["a"]
		var b := e["b"]
		if a >= nodes.size() or b >= nodes.size():
			continue
		var p1 := nodes[a]
		var p2 := nodes[b]

		var color := Color(1,1,1) # blanco por defecto
		match e["state"]:
			"normal":
				color = Color(1,1,1)
			"visited":
				color = Color(0.2, 0.8, 0.2) # verde
			"path":
				color = Color(1, 0.85, 0)   # amarillo
			"mst":
				color = Color(0.0, 0.7, 0.7) # cian/verde
			"flow_used":
				color = Color(0.0, 1, 1)    # cyan
			"saturated":
				color = Color(1, 0.2, 0.2)  # rojo
			_:
				color = Color(1,1,1)

		draw_line(p1, p2, color, 3)

		# peso en el medio
		var mid := (p1 + p2) * 0.5
		var peso_text := str(int(e["weight"]))
		if font:
			draw_string(font, mid + Vector2(-8, -8), peso_text)
		else:
			draw_string(get_font("font"), mid + Vector2(-8, -8), peso_text)

	# dibujar nodos
	for i in range(nodes.size()):
		var pos := nodes[i]
		var col := Color(0.7, 0.7, 1)
		if i in selected:
			col = Color(1, 0.9, 0.2) # amarillo
		draw_circle(pos, radius, col)
		# id texto
		var id_text := str(i)
		if font:
			draw_string(font, pos + Vector2(-6, 6), id_text)
		else:
			draw_string(get_font("font"), pos + Vector2(-6, 6), id_text)

# Input: selección por clic
func _input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := event.position
		for i in range(nodes.size()):
			if nodes[i].distance_to(pos) <= radius:
				# toggle o agregar (mantiene orden)
				if i in selected:
					selected.erase(i)
				else:
					selected.append(i)
				queue_redraw()
				return
