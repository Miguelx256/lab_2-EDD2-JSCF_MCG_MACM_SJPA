extends Node2D

var nodes = []          # Posiciones de nodos
var edges = []          # Aristas (pares de índices)
var selected_nodes = [] # Índices de nodos seleccionados
var node_radius = 15

func _ready():
	set_process_input(true)

func set_graph(_nodes, _edges):
	nodes = _nodes
	edges = _edges
	selected_nodes.clear()
	queue_redraw()

func _draw():
	# Dibujar aristas
	for e in edges:
		draw_line(nodes[e[0]], nodes[e[1]], Color.WHITE, 2)
	
	# Dibujar nodos
	for i in range(nodes.size()):
		var pos = nodes[i]
		var color = Color(0.2, 0.6, 1)
		if i in selected_nodes:
			color = Color(0, 1, 0) # verde si está seleccionado
		draw_circle(pos, node_radius, color)

		var font = get_theme_font("font")
		if font:
			draw_string(font, pos + Vector2(-6, -15), char(65 + i), Color.WHITE)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		for i in range(nodes.size()):
			if mouse_pos.distance_to(nodes[i]) < node_radius:
				_toggle_selection(i)
				queue_redraw()
				break

func _toggle_selection(i):
	if i in selected_nodes:
		selected_nodes.erase(i)
	else:
		selected_nodes.append(i)
