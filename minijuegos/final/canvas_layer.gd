extends CanvasLayer

@onready var button = $"gene grafo"
@onready var graph_area = $Node2D   # ajusta ruta si tu GraphArea está fuera del Control

var nodes = []
var edges = []

func _ready():
	button.text = "Generador de grafo"
	button.connect("pressed", Callable(self, "_on_generar_grafo_pressed"))

func _on_generar_grafo_pressed():
	_generate_random_graph()
	graph_area.queue_redraw()# Node2D.update()

func _generate_random_graph():
	nodes.clear()
	edges.clear()
	var num_nodes = randi_range(4, 5)
	for i in range(num_nodes):
		nodes.append(Vector2(randi_range(100, 800), randi_range(100, 500)))
	for i in range(num_nodes):
		for j in range(i + 1, num_nodes):
			if randf() < 0.5:
				edges.append([i, j])
	print("🔹 Grafo generado con %s nodos y %s aristas" % [num_nodes, edges.size()])

# Esta función debe existir si GraphArea va a llamar a parent._draw_graph(self)
func _draw_graph(canvas_item):
	var color_node = Color(0.2, 0.6, 1)
	var color_edge = Color(1, 1, 1)
	for edge in edges:
		var a = nodes[edge[0]]
		var b = nodes[edge[1]]
		canvas_item.draw_line(a, b, color_edge, 2)
	for i in range(nodes.size()):
		canvas_item.draw_circle(nodes[i], 10, color_node)
