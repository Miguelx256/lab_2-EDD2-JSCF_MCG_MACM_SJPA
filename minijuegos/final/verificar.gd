# verificar.gd
# Funciones para verificar las tareas del usuario

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
