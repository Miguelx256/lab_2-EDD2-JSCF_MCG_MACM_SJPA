extends Node2D

var nodes: Array = [] # posiciones: Vector2
var edges: Array = [] # array de diccionarios
var selected: Array = [] # índices seleccionados
var radius: float = 22.0
var font: Font = null
var selected_edges: Array = [] # NUEVO: índices de las aristas seleccionadas

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

func get_selected_edges() -> Array:
	return selected_edges.duplicate()

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
	for i in range(edges.size()):
		var e = edges[i]
		var a: int = e["a"]
		var b: int = e["b"]
		
		# Asumo que a y b son índices válidos
		
		var p1: Vector2 = nodes[a]
		var p2: Vector2 = nodes[b]
		
		var color: Color = Color.WHITE
		var thickness: float = 3.0
		
		# PRIORIDAD 1: Arista Seleccionada por el jugador (Selección en Etapa 2)
		if i in selected_edges:
			color = Color(1.0, 0.5, 0.0) # Naranja brillante
			thickness = 5.0
			
		# PRIORIDAD 2: Estado del Algoritmo (Sobrescribe si hay un estado)
		match e["state"]:
			"visited": color = Color(0.2, 0.8, 0.2)
			"path": color = Color(1.0, 0.85, 0.0) # Para el camino más corto
			"mst": color = Color(0.0, 0.7, 0.7) # Para la próxima etapa
			_: pass # Mantiene el color de selección o blanco
			
		# Aplicar el color y grosor final
		draw_line(p1, p2, color, thickness)
		
		# ========================================================
		# 🎨 DIBUJAR EL PESO DE LA ARISTA (Entero y Mejorado)
		# ========================================================
		if font and e.has("weight"): 
			# Forzamos el peso a ser un entero para la visualización
			var weight_text: String = str(int(e["weight"])) 
			var center_pos: Vector2 = (p1 + p2) / 2
			
			# Cálculo del offset (10px perpendicular a la línea)
			var offset: Vector2 = (p2 - p1).normalized().rotated(PI/2) * 10 
			
			# --- 1. Dibujar Fondo Semitransparente (Mejora Estética) ---
			var text_size: Vector2 = font.get_string_size(weight_text)
			var padding: Vector2 = Vector2(4, 2)
			var bg_size: Vector2 = text_size + padding * 2
			
			var bg_color: Color = Color(1.0, 1.0, 0.8, 0.8) # Amarillo muy claro, 80% opacidad
			
			var bg_center_pos: Vector2 = center_pos + offset
			var bg_top_left: Vector2 = bg_center_pos - bg_size / 2
			
			draw_rect(Rect2(bg_top_left, bg_size), bg_color)
			
			# --- 2. Dibujar el Texto Negro ---
			# Ajusta la posición para centrar el texto sobre el fondo
			var text_draw_pos: Vector2 = bg_center_pos + Vector2(-text_size.x/2, font.get_ascent() / 2)
			
			draw_string(font, text_draw_pos, weight_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLACK)
	
	# --- DIBUJAR NODOS ---
	for i in range(nodes.size()):
		var pos: Vector2 = nodes[i]
		var col: Color = Color(0.6, 0.6, 1.0)
		if i in selected:
			col = Color(1.0, 0.9, 0.2)
		draw_circle(pos, radius, col)
		
		# Texto del ID
		var id_text: String = str(i)
		# Posición ajustada para centrar el ID dentro del círculo
		draw_string(font, pos + Vector2(-6, 6), id_text)

## ----------------------------------------------------------------------------
# INPUT PARA SELECCIÓN DE NODOS Y ARISTAS
# ----------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		var edge_selected = false
		
		# 1. Detección de Clic en ARISTA
		# Busca si el clic está cerca de algún segmento de línea (tolerancia de 10 pixeles)
		for i in range(edges.size()):
			var e = edges[i]
			var p1: Vector2 = nodes[e.a]
			var p2: Vector2 = nodes[e.b]
			
			# Calcula la distancia del clic al segmento de línea
			var distance_to_line = Geometry2D.get_closest_point_to_segment(pos, p1, p2).distance_to(pos)
			
			if distance_to_line < 10.0: 
				if i in selected_edges:
					selected_edges.erase(i)
				else:
					selected_edges.append(i)
				queue_redraw()
				edge_selected = true
				break # Solo selecciona una arista por clic

		if edge_selected:
			return

		# 2. Detección de Clic en NODO (Si no se seleccionó ninguna arista)
		for i in range(nodes.size()):
			if nodes[i].distance_to(pos) <= radius:
				if i in selected:
					selected.erase(i)
				else:
					selected.append(i)
				queue_redraw()
				return
