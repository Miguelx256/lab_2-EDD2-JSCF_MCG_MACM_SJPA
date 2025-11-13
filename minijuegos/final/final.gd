extends Control

@onready var button_generar = $GeneradorButton
@onready var button_verificar = $VerificarButton
@onready var mensaje_label = $MensajeLabel
@onready var graph_area = $GraphArea

var nodes = []
var edges = []

var tasks = ["recorrido", "camino mínimo", "reconstrucción", "flujo"]
var current_task_index = 0

func _ready():
	button_generar.text = "Generar grafo"
	button_verificar.text = "Verificar"
	button_generar.connect("pressed", Callable(self, "_on_generar_grafo_pressed"))
	button_verificar.connect("pressed", Callable(self, "_on_verificar_pressed"))
	_show_message("Presiona 'Generar grafo' para comenzar.")

func _on_generar_grafo_pressed():
	_generate_connected_graph()
	current_task_index = 0
	graph_area.set_graph(nodes, edges)
	_show_message("🔹 Nuevo grafo generado. Empieza con la tarea: %s" % tasks[current_task_index])

func _on_verificar_pressed():
	var task = tasks[current_task_index]
	var seleccion = graph_area.selected_nodes

	if seleccion.is_empty():
		_show_message("⚠️ Debes seleccionar al menos un nodo para '%s'." % task)
		return

	# 🔹 Aquí luego pondrás tus verificaciones reales
	_show_message("✅ Seleccionaste los nodos: %s\nTarea '%s' completada correctamente." % [seleccion, task])

	current_task_index += 1
	if current_task_index < tasks.size():
		_show_message("➡️ Siguiente tarea: %s" % tasks[current_task_index])
	else:
		_show_message("🎉 ¡Has completado todas las tareas del grafo!")

func _generate_connected_graph():
	nodes.clear()
	edges.clear()
	var num_nodes = randi_range(4, 6)
	
	# Crear posiciones
	for i in range(num_nodes):
		nodes.append(Vector2(randi_range(100, 800), randi_range(100, 500)))

	# Asegurar conexión
	for i in range(1, num_nodes):
		var j = randi_range(0, i - 1)
		edges.append([i, j])

	# Agregar algunas aristas extra
	for i in range(num_nodes):
		for j in range(i + 1, num_nodes):
			if not _edge_exists(i, j) and randf() < 0.4:
				edges.append([i, j])

func _edge_exists(i, j):
	for e in edges:
		if (e[0] == i and e[1] == j) or (e[0] == j and e[1] == i):
			return true
	return false

func _show_message(msg: String):
	if mensaje_label:
		mensaje_label.text = msg
