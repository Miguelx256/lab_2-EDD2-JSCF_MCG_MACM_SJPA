extends Control
# Asegúrate de que estas dos líneas estén aquí
const NODO_ESCENA = preload("uid://cnk5sk6p3yy7j")


# =========================
# VARIABLES GLOBALES
# =========================
var grafo = null                  # Contendrá la estructura del grafo
var tareas = []                   # Lista de tareas
var tarea_actual = 0              # Índice de la tarea actual
var seleccion_usuario = []        # Lista con la selección del usuario (nodos o aristas)
var nodos = []            # Lista de posiciones de nodos
var aristas = []          # Lista de aristas: [[nodo1, nodo2, peso], ...]
var nodo_radio = 20

# Referencias a nodos
@onready var btn_generar = $CanvasLayer/generador
@onready var btn_verificar = $CanvasLayer/verificar
@onready var btn_siguiente = $CanvasLayer/siguiente
@onready var nodo_grafo = $CanvasLayer/Node2D
# ¡IMPORTANTE! Asegúrate de que $LabelTarea y $LabelResultado existan en tu escena
@onready var label_tarea = $CanvasLayer/LabelTarea       
@onready var label_resultado = $CanvasLayer/LabelResultado

# =========================
# FUNCIONES DE INICIALIZACIÓN
# =========================
func _ready():
	# Conectar señales de botones usando la sintaxis CORRECTA de Godot 4 (Callable)
	btn_generar.connect("pressed", _on_btn_generar_pressed)
	btn_verificar.connect("pressed", _on_btn_verificar_pressed)
	btn_siguiente.connect("pressed", _on_btn_siguiente_pressed)

	# Inicializar tareas
	tareas = ["Recorrido por profundidad", "Camino mínimo", "Reconstrucción", "Flujo"]

	# Mostrar la primera tarea
	mostrar_tarea()

# =========================
# FUNCIONES DE BOTONES
# =========================
func _on_btn_generar_pressed():
	generar_grafo()
	dibujar_grafo()

func _on_btn_verificar_pressed():
	verificar_tarea_actual()

func _on_btn_siguiente_pressed():
	if tarea_actual < tareas.size() - 1:
		tarea_actual += 1
		seleccion_usuario.clear()
		mostrar_tarea()
		# Redibujar puede ser necesario si la tarea cambia la visualización
		# Por ejemplo, si el camino mínimo necesita un color especial
		# dibujar_grafo() 

# =========================
# FUNCIONES DEL JUEGO
# =========================
func mostrar_tarea():
	label_tarea.text = "Tarea: " + tareas[tarea_actual]

func verificar_tarea_actual():
	match tareas[tarea_actual]:
		"Recorrido por profundidad":
			verificar_recorrido()
		"Camino mínimo":
			verificar_camino_minimo()
		"Reconstrucción":
			# Lógica de verificación para reconstrucción
			label_resultado.text = "Pendiente de implementar."
		"Flujo":
			# Lógica de verificación para flujo
			label_resultado.text = "Pendiente de implementar."
		_:
			print("Tarea no implementada aún.")

func verificar_recorrido():
	if seleccion_usuario == grafo.obtener_recorrido_correcto():
		label_resultado.text = "¡Correcto!"
	else:
		label_resultado.text = "Incorrecto, intenta de nuevo."

func verificar_camino_minimo():
	if seleccion_usuario == grafo.obtener_camino_minimo():
		label_resultado.text = "¡Correcto!"
	else:
		label_resultado.text = "Incorrecto, intenta de nuevo."

# =========================
# FUNCIONES DEL GRAFO
# =========================
func generar_grafo():
	# Llama al script del grafo para crear uno nuevo aleatorio
	# Asume que esta función crea grafo.nodos (Vector2) y grafo.aristas (Dictionary)
	grafo.generar_aleatorio(4, 5)

func dibujar_grafo():
	# 1. Limpiar el dibujo anterior
	for child in nodo_grafo.get_children(): 
		child.queue_free()

	if not grafo:
		return

	# 2. Dibujar Aristas y Pesos (Líneas y Labels)
	if grafo.has("aristas") and grafo.has("nodos"):
		# CORRECCIÓN AQUÍ: ELIMINAR 'var'
		for arista in grafo.aristas: 
			var pos_inicio = grafo.nodos[arista.inicio]
			var pos_fin = grafo.nodos[arista.fin]

			# Línea (Arista)
			var linea = Line2D.new()
			linea.points = [pos_inicio, pos_fin]
			linea.width = 3.0
			linea.default_color = Color(0.7, 0.7, 0.7, 0.6)
			nodo_grafo.add_child(linea)

			# Etiqueta (Peso)
			var peso_label = Label.new()
			peso_label.text = str(arista.peso)
			peso_label.position = (pos_inicio + pos_fin) / 2.0
			peso_label.position -= Vector2(10, 15)
			nodo_grafo.add_child(peso_label)

	# 3. Dibujar los NODOS
	if grafo.has("nodos"):
		# CORRECCIÓN AQUÍ: ELIMINAR 'var'
		for i in range(grafo.nodos.size()): 
			var nodo_inst = NODO_ESCENA.instantiate()
			
			nodo_inst.nodo_id = i
			nodo_inst.position = grafo.nodos[i]
			
			nodo_inst.connect("nodo_seleccionado", _on_nodo_seleccionado)
			
			nodo_grafo.add_child(nodo_inst)
# =========================
# FUNCIONES DE SEÑAL
# =========================
func _on_nodo_seleccionado(id):
	if id in seleccion_usuario:
		seleccion_usuario.erase(id)
	else:
		seleccion_usuario.append(id)
		

# =========================
# FUNCIONES PRINCIPALES
# =========================
func generar_aleatorio(num_nodos: int, max_aristas_extra: int = 5) -> void:
	"""
    Genera un grafo conexo con num_nodos y algunas aristas adicionales.
	"""
	nodos.clear()
	aristas.clear()
	
	# 1️⃣ Generar posiciones aleatorias de nodos
	for i in range(num_nodos):
		var pos = Vector2(
			randi() % int(get_viewport_rect().size.x - 100) + 50,
			randi() % int(get_viewport_rect().size.y - 100) + 50
		)
		nodos.append(pos)
	
	# 2️⃣ Asegurar conectividad (usar árbol aleatorio)
	var nodos_disponibles = nodos.duplicate()
	var nodos_conectados = [nodos_disponibles.pop_back()]
	
	while nodos_disponibles.size() > 0:
		var nuevo = nodos_disponibles.pop_back()
		var conectado = nodos_conectados[randi() % nodos_conectados.size()]
		var peso = randi() % 99 + 1   # Peso 1-99
		aristas.append([nodos.find(conectado), nodos.find(nuevo), peso])
		nodos_conectados.append(nuevo)
	
	# 3️⃣ Agregar algunas aristas extra aleatorias
	for i in range(max_aristas_extra):
		var n1 = randi() % num_nodos
		var n2 = randi() % num_nodos
		if n1 != n2 and not arista_existe(n1, n2):
			var peso = randi() % 99 + 1
			aristas.append([n1, n2, peso])
	
	update()  # Llamar a _draw() para dibujar el grafo

# =========================
# FUNCIONES AUXILIARES
# =========================
func arista_existe(n1: int, n2: int) -> bool:
	for a in aristas:
		if (a[0] == n1 and a[1] == n2) or (a[0] == n2 and a[1] == n1):
			return true
	return false

# =========================
# DIBUJO DEL GRAFO
# =========================
func _draw() -> void:
	# Dibujar aristas
	for a in aristas:
		var p1 = nodos[a[0]]
		var p2 = nodos[a[1]]
		draw_line(p1, p2, Color.white, 2)
		# Dibujar peso en el medio
		var mid = (p1 + p2) / 2
		draw_string(get_font("font"), mid, str(a[2]), Color.yellow)
	
	# Dibujar nodos
	for i in range(nodos.size()):
		draw_circle(nodos[i], nodo_radio, Color.red)
		draw_string(get_font("font"), nodos[i] + Vector2(-5, -nodo_radio-5), str(i), Color.white)

# =========================
# FUNCIONES PARA VERIFICACIÓN
# =========================
func obtener_recorrido_correcto() -> Array:
	# Ejemplo de recorrido correcto (profundidad DFS desde nodo 0)
	var visitados = []
	_dfs(0, visitados)
	return visitados

func _dfs(nodo: int, visitados: Array) -> void:
	if nodo in visitados:
		return
	visitados.append(nodo)
	for a in aristas:
		if a[0] == nodo:
			_dfs(a[1], visitados)

func obtener_camino_minimo() -> Array:
	# Aquí podrías implementar Dijkstra o cualquier camino mínimo
	# Retornar un ejemplo vacío por ahora
	return []

func _on_BotonSiguiente_pressed():
	tarea_actual += 1
	seleccion_usuario.clear()
	mostrar_tarea()


# =========================
# VERIFICAR RECORRIDO (DFS)
# =========================
func verificar_recorrido2(seleccion_usuario: Array, grafo) -> bool:
	"""
    Verifica si la selección del usuario coincide con un recorrido DFS válido
    desde el nodo 0.
	"""
	var visitados = []
	_dfs2(0, grafo.aristas, visitados)
	
	# Comparar con la selección del usuario
	return visitados == seleccion_usuario

func _dfs2(nodo: int, aristas: Array, visitados: Array) -> void:
	if nodo in visitados:
		return
	visitados.append(nodo)
	for a in aristas:
		if a[0] == nodo:
			_dfs2(a[1], aristas, visitados)

# =========================
# VERIFICAR CAMINO MÍNIMO (Dijkstra)
# =========================
func verificar_camino_minimo2(seleccion_usuario: Array, grafo, inicio: int = 0, fin: int = -1) -> bool:
	"""
    Verifica si la selección del usuario es el camino mínimo entre inicio y fin.
	"""
	if fin == -1:
		fin = grafo.nodos.size() - 1  # Por defecto último nodo
	
	var camino_minimo = _dijkstra2(grafo, inicio, fin)
	
	return seleccion_usuario == camino_minimo

func _dijkstra2(grafo, inicio: int, fin: int) -> Array:
	var dist = {}
	var prev = {}
	var Q = []
	
	# Inicialización
	for i in range(grafo.nodos.size()):
		dist[i] = INF
		prev[i] = null
		Q.append(i)
	dist[inicio] = 0
	
	while Q.size() > 0:
		# Nodo con distancia mínima
		Q.sort_custom(self, "_sort_by_dist", dist)
		var u = Q.pop_front()
		if u == fin:
			break
		
		for a in grafo.aristas:
			if a[0] == u:
				var v = a[1]
				var alt = dist[u] + a[2]
				if alt < dist[v]:
					dist[v] = alt
					prev[v] = u
	
	# Reconstruir camino
	var s = []
	var u = fin
	while u != null:
		s.insert(0, u)
		u = prev[u]
	return s

func _sort_by_dist2(a, b, dist):
	return dist[a] - dist[b]

# =========================
# VERIFICAR RECONSTRUCCIÓN
# =========================
func verificar_reconstruccion2(seleccion_usuario: Array, grafo) -> bool:
	"""
    Ejemplo: verifica si el usuario reconstruyó correctamente la lista de aristas.
	"""
	var aristas_usuario = seleccion_usuario.duplicate()
	var aristas_grafo = grafo.aristas.duplicate()
	
	# Ordenar para comparar fácilmente
	aristas_usuario.sort()
	aristas_grafo.sort()
	
	return aristas_usuario == aristas_grafo

# =========================
# VERIFICAR FLUJO MÁXIMO
# =========================
func verificar_flujo2(seleccion_usuario: Array, grafo, fuente: int = 0, sumidero: int = -1) -> bool:
	"""
    Verifica si el flujo calculado por el usuario es correcto.
    seleccion_usuario podría ser un array de flujos por arista.
	"""
	if sumidero == -1:
		sumidero = grafo.nodos.size() - 1
	
	var flujo_correcto = _flujo_maximo2(grafo, fuente, sumidero)
	
	return seleccion_usuario == flujo_correcto

func _flujo_maximo2(grafo, fuente: int, sumidero: int) -> Array:
	"""
    Implementación simple de Ford-Fulkerson para flujo máximo.
    Devuelve un array de flujos por arista en el mismo orden que grafo.aristas
	"""
	var flujo = []
	for a in grafo.aristas:
		flujo.append(0)
	
	# Aquí se puede implementar un algoritmo completo si es necesario
	# Por ahora devolvemos un flujo ejemplo (todo cero)
	return flujo
