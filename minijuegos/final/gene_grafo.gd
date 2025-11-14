extends Node2D

# =========================
# VARIABLES
# =========================
var nodos = []            # Lista de posiciones de nodos
var aristas = []          # Lista de aristas: [[nodo1, nodo2, peso], ...]
var nodo_radio = 20

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
			randi() % (get_viewport_rect().size.x - 100) + 50,
			randi() % (get_viewport_rect().size.y - 100) + 50
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
