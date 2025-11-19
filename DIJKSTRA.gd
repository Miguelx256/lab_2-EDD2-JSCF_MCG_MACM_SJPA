extends Control

#
# MINI-JUEGO: Camino Mínimo con Dijkstra
#

const Grafo = preload("res://core/Grafo.gd")
const Nodo  = preload("res://core/Nodo.gd")

# -------------------------
# CONFIGURACIÓN GENERAL
# -------------------------
const MIN_NODES := 5
const MAX_NODES := 10
const NODE_RADIUS := 20
const HIT_DIST := 22
const EDGE_COLOR := Color.WHITE
const PLAYER_COLOR := Color(0.2, 0.8, 1.0)
const DIJKSTRA_COLOR := Color(1.0, 0.6, 0.2)
const NODE_COLOR := Color.DODGER_BLUE

var grafo:Grafo
var nodos:Array[Nodo] = []
var posiciones:Dictionary = {}
var camino_jugador:Array[int] = []
var dijkstra_path:Array[int] = []
var dijkstra_cost:float = 0.0
var player_cost:float = 0.0

var start_node:int = -1
var goal_node:int = -1

@onready var new_btn   :Button = $NewButton
@onready var clear_btn :Button = $ClearButton
@onready var check_btn :Button = $CheckButton
@onready var info_lbl  :Label  = $InfoLabel
@onready var next_lvl  :Button = $NextLvl
@onready var bg: CanvasLayer = $BG
@onready var dijkstra_fondo: TextureRect = $BG/Dijkstra

func _ready():
	bg.layer = -100  # dibuja detrás de todo
	dijkstra_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	dijkstra_fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dijkstra_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	next_lvl.hide()
	new_btn.pressed.connect(_crear_grafo)
	clear_btn.pressed.connect(_clear)
	check_btn.pressed.connect(_check)

	_crear_grafo()

# -------------------------------------------------------------
# CREAR GRAFO
# -------------------------------------------------------------
func _crear_grafo():
	grafo = Grafo.new()
	nodos.clear()
	posiciones.clear()
	camino_jugador.clear()
	dijkstra_path.clear()

	var num:int = randi_range(MIN_NODES, MAX_NODES)

	# Crear nodos
	for i in range(num):
		var n := Nodo.new(str(i))  # ✔ ID como STRING para compatibilidad con tu Nodo.gd
		grafo.agregar_nodo(n)
		nodos.append(n)

	# Conexión lineal (mínimo)
	for i in range(num - 1):
		grafo.conectar_nodo(nodos[i], nodos[i+1], randf_range(1.0, 10.0))

	# Extra edges
	var extras := randi_range(1, 2)
	for _i in range(extras):
		var a := nodos[randi_range(0, num-1)]
		var b := nodos[randi_range(0, num-1)]
		if a != b:
			grafo.conectar_nodo(a, b, randf_range(1.0, 10.0))

	_asignar_posiciones()

	# Elegir nodo inicio y fin
	start_node = randi_range(0, nodos.size() - 1)
	goal_node = randi_range(0, nodos.size() - 1)
	while goal_node == start_node:
		goal_node = randi_range(0, nodos.size() - 1)

	_update_info()
	queue_redraw()

# -------------------------------------------------------------
# POSICIONES EN CÍRCULO
# -------------------------------------------------------------
func _asignar_posiciones():
	var total:int = nodos.size()
	var centro := Vector2(400, 250)
	var radio := 180.0

	for i in range(total):
		var ang:float = TAU * float(i) / float(total)
		posiciones[nodos[i]] = centro + Vector2(cos(ang), sin(ang)) * radio

# -------------------------------------------------------------
# INPUT PARA SELECCIONAR NODOS
# -------------------------------------------------------------
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p:Vector2 = get_local_mouse_position()
		var idx:int = _nodo_clickeado(p)
		if idx != -1:
			_agregar_al_camino(idx)
			_update_info()
			queue_redraw()

func _nodo_clickeado(p:Vector2) -> int:
	for i in range(nodos.size()):
		if posiciones[nodos[i]].distance_to(p) <= HIT_DIST:
			return i
	return -1

func _agregar_al_camino(i:int):
	if camino_jugador.size() == 0 or camino_jugador[-1] != i:
		camino_jugador.append(i)

# -------------------------------------------------------------
# LIMPIAR CAMINO
# -------------------------------------------------------------
func _clear():
	camino_jugador.clear()
	dijkstra_path.clear()
	player_cost = 0.0
	dijkstra_cost = 0.0
	_update_info()
	queue_redraw()

# -------------------------------------------------------------
# BOTÓN CHECK — EJECUTAR DIJKSTRA
# -------------------------------------------------------------
func _check():
	if camino_jugador.size() < 2:
		info_lbl.text = "Selecciona nodos formando un camino desde %d hasta %d." % [start_node, goal_node]
		return

	# Verificar que el jugador realmente haga de start → goal
	if camino_jugador[0] != start_node or camino_jugador[-1] != goal_node:
		info_lbl.text = "El camino debe ir desde %d hasta %d." % [start_node, goal_node]
		return

	var result := dijkstra(start_node, goal_node)
	dijkstra_path = result["path"]
	dijkstra_cost = result["cost"]

	player_cost = _costo_camino_jugador()

	var win:bool = player_cost <= dijkstra_cost

	info_lbl.text = (
		"Camino jugador: %s (%.2f)\n"
		+ "Dijkstra: %s (%.2f)\n\n"
		+ ("GANASTE 🎉" if win else "PERDISTE ❌")
	) % [str(camino_jugador), player_cost, str(dijkstra_path), dijkstra_cost]

	# --- ocultar botones si gana ---
	if win:
		clear_btn.hide()
		check_btn.hide()
		next_lvl.show()
		# también podrías desactivar otros inputs aquí si quieres

	queue_redraw()


# -------------------------------------------------------------
# COSTO DEL CAMINO DEL JUGADOR
# -------------------------------------------------------------
func _costo_camino_jugador() -> float:
	var total:float = 0.0
	for i in range(camino_jugador.size() - 1):
		var u:Nodo = nodos[camino_jugador[i]]
		var v:Nodo = nodos[camino_jugador[i+1]]
		if not u.adyacente.has(v):
			return INF
		total += u.adyacente[v]
	return total

# -------------------------------------------------------------
# DIJKSTRA REAL
# -------------------------------------------------------------
func dijkstra(start:int, goal:int) -> Dictionary:
	var dist:Dictionary = {}
	var prev:Dictionary = {}
	var Q:Array[int] = []

	for i in range(nodos.size()):
		dist[i] = INF
		prev[i] = -1
		Q.append(i)

	dist[start] = 0.0

	while Q.size() > 0:
		var u:int = Q[0]
		for x in Q:
			if dist[x] < dist[u]:
				u = x
		Q.erase(u)

		if u == goal:
			break

		for vecino in nodos[u].adyacente.keys():
			var vid:int = int(vecino.id)
			var alt:float = dist[u] + nodos[u].adyacente[vecino]
			if alt < dist[vid]:
				dist[vid] = alt
				prev[vid] = u

	# reconstruir camino
	var path:Array[int] = []
	var u:int = goal
	while u != -1:
		path.push_front(u)
		u = prev[u]

	return {
		"path": path,
		"cost": dist[goal]
	}

# -------------------------------------------------------------
# INFO TEXT
# -------------------------------------------------------------
func _update_info():
	info_lbl.text = "Selecciona nodos desde %d → %d.\nClick en CHECK para comparar con Dijkstra." \
		% [start_node, goal_node]

# -------------------------------------------------------------
# DRAW
# -------------------------------------------------------------
func _draw():

	# DIBUJAR ARISTAS
	for u in nodos:
		var pu:Vector2 = posiciones[u]
		for v in u.adyacente.keys():
			var pv:Vector2 = posiciones[v]
			draw_line(pu, pv, EDGE_COLOR, 2)

			var weight:float = round(u.adyacente[v] * 10.0) / 10.0
			var mid := (pu + pv) * 0.5
			draw_string(get_theme_default_font(), mid, str(weight), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.YELLOW)

	# CAMINO OPTIMO DIJKSTRA
	if dijkstra_path.size() >= 2:
		for i in range(dijkstra_path.size() - 1):
			var a := nodos[dijkstra_path[i]]
			var b := nodos[dijkstra_path[i+1]]
			draw_line(posiciones[a], posiciones[b], DIJKSTRA_COLOR, 4)

	# CAMINO DEL JUGADOR
	if camino_jugador.size() >= 2:
		for i in range(camino_jugador.size() - 1):
			var a := nodos[camino_jugador[i]]
			var b := nodos[camino_jugador[i+1]]
			draw_line(posiciones[a], posiciones[b], PLAYER_COLOR, 4)

	# NODOS
	for i in range(nodos.size()):
		var p:Vector2 = posiciones[nodos[i]]
		draw_circle(p, NODE_RADIUS, NODE_COLOR)
		draw_string(get_theme_default_font(), p + Vector2(-6,6), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)

	# Inicio (verde)
	draw_circle(posiciones[nodos[start_node]], NODE_RADIUS + 4.0, Color.GREEN)

	# Fin (rojo)
	draw_circle(posiciones[nodos[goal_node]], NODE_RADIUS + 4.0, Color.RED)


func _on_next_lvl_button_down() -> void:
	get_tree().change_scene_to_file("res://minijuegos/Arbol de expansión mínima/Expansión mínima.tscn")
