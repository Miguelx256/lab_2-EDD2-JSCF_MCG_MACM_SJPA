extends Node2D

var nodes: Array = []           # posiciones: Vector2
var edges: Array = []           # array de diccionarios
var selected: Array = []        # índices seleccionados
var radius: float = 22.0
var font: Font = null

func _ready() -> void:
	font = ThemeDB.fallback_font


# ----------------------------------------------------------------------------
# RECIBE POSICIONES Y ARISTAS DESDE EL MAIN
# ----------------------------------------------------------------------------
func set_graph(p_nodes: Array, p_edges: Array) -> void:
	nodes = p_nodes.duplicate()

	edges = []
	for e in p_edges:
		edges.append({
			"a": int(e["a"]),
			"b": int(e["b"]),
			"weight": float(e["weight"]),
			"state": String(e["state"])
		})

	selected.clear()
	queue_redraw()


func get_selected() -> Array:
	return selected.duplicate()


# ----------------------------------------------------------------------------
# RESALTADO DE NODOS EN ORDEN (DFS)
# ----------------------------------------------------------------------------
func highlight_nodes_in_order(order: Array, tipo: String = "visited") -> void:
	selected = order.duplicate()
	queue_redraw()


# ----------------------------------------------------------------------------
# DIBUJAR GRAFO
# ----------------------------------------------------------------------------
func _draw() -> void:
	# --- DIBUJAR ARISTAS ---
	for e in edges:
		var a: int = e["a"]
		var b: int = e["b"]
		if a >= nodes.size() or b >= nodes.size():
			continue

		var p1: Vector2 = nodes[a]
		var p2: Vector2 = nodes[b]

		var color: Color = Color.WHITE

		match e["state"]:
			"visited":
				color = Color(0.2, 0.8, 0.2)
			"path":
				color = Color(1.0, 0.85, 0.0)
			"mst":
				color = Color(0.0, 0.7, 0.7)
			"flow_used":
				color = Color(0.0, 1.0, 1.0)
			"saturated":
				color = Color(1.0, 0.2, 0.2)
			_:
				color = Color.WHITE

		draw_line(p1, p2, color, 3.0)

		# texto del peso
		var mid: Vector2 = (p1 + p2) * 0.5
		var peso_text: String = str(int(e["weight"]))
		draw_string(font, mid + Vector2(-8, -8), peso_text)


	# --- DIBUJAR NODOS ---
	for i in range(nodes.size()):
		var pos: Vector2 = nodes[i]
		var col: Color = Color(0.6, 0.6, 1.0)

		if i in selected:
			col = Color(1.0, 0.9, 0.2)

		draw_circle(pos, radius, col)

		# texto del id
		var id_text: String = str(i)
		draw_string(font, pos + Vector2(-6, 6), id_text)


# ----------------------------------------------------------------------------
# INPUT PARA SELECCIÓN DE NODOS
# ----------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		for i in range(nodes.size()):
			if nodes[i].distance_to(pos) <= radius:
				if i in selected:
					selected.erase(i)
				else:
					selected.append(i)
				queue_redraw()
				return
