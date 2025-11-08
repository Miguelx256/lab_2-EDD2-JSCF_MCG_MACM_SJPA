extends Control

const NODE_COUNT      : int = 4
const EXTRA_EDGES     : int = 2      
const NODE_RADIUS     : float = 16.0
const EDGE_THICKNESS  : float = 3.0
const NODE_HIT_DIST   : float = 18.0
const MARGIN          : float = 64.0

const SOURCE_COLOR        : Color = Color(0.10, 0.25, 0.90)  
const SINK_COLOR          : Color = Color(0.20, 0.85, 0.40)  
const NODE_BASE_INNER     : Color = Color(0.92, 0.96, 1.00)
const NODE_BASE_BORDER    : Color = Color(0.15, 0.20, 0.28)

const SUCCESS_MSG := "Flujo seguro establecido. El ataque ha sido contenido. NEMESIS ha sido aislado"

# ---------- Estructuras ----------
class Edge:
	var u:int
	var v:int
	var cap:int
	var flow:int = 0
	func _init(_u:int, _v:int, _cap:int) -> void:
		u = _u; v = _v; cap = _cap

class REdge:
	var to:int
	var cap:int
	var rev:int
	var draw_idx:int
	var forward:bool

# ---------- Estado ----------
var nodes: Array[Vector2] = []
var edges: Array[Edge] = []

var s: int = -1    # fuente (primer click)
var t: int = -1    # sumidero (segundo click)
var max_flow: int = 0
var reveal_flow: bool = false

var freeze_info: bool = false
var info_cache: String = ""
var G: Array = []  # red residual: filas Array con REdge (sin tipos anidados)

# ---------- UI ----------
@onready var new_btn   : Button = get_node_or_null("NewButton")
@onready var clear_btn : Button = get_node_or_null("ClearButton")
@onready var check_btn : Button = get_node_or_null("CheckButton")
@onready var info_lbl  : Label  = get_node_or_null("InfoLabel")

func _ready() -> void:
	randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	if info_lbl:
		info_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	if new_btn:   new_btn.pressed.connect(_new_graph)
	if clear_btn: clear_btn.pressed.connect(_clear_all)
	if check_btn: check_btn.pressed.connect(_on_check)

	call_deferred("_new_graph")

# ---------- Input ----------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = get_local_mouse_position()
		var hit := _pick_node(p)
		if hit != -1:
			_select_node(hit)
			_update_info()
			queue_redraw()

func _pick_node(p: Vector2) -> int:
	var best := -1
	var bd := 1e9
	for i in nodes.size():
		var d := nodes[i].distance_to(p)
		if d < NODE_HIT_DIST and d < bd:
			bd = d; best = i
	return best

func _select_node(v:int) -> void:
	if s == -1:
		s = v
	elif t == -1 and v != s:
		t = v
	else:
		if v == s:
			s = -1
		elif v == t:
			t = -1
		else:
			s = v
			t = -1
	reveal_flow = false
	freeze_info = false

# ---------- Grafo ----------
func _new_graph() -> void:
	nodes.clear()
	edges.clear()
	s = -1; t = -1; max_flow = 0
	reveal_flow = false; freeze_info = false

	var rect: Vector2 = get_viewport().get_visible_rect().size
	for i in NODE_COUNT:
		nodes.append(Vector2(
			randf_range(MARGIN, maxf(MARGIN + 1.0, rect.x - MARGIN)),
			randf_range(MARGIN, maxf(MARGIN + 1.0, rect.y - MARGIN))
		))

	# Backbone 0->1->2->... para asegurar caminos
	for i in range(1, NODE_COUNT):
		_add_edge_unique(i - 1, i, _rand_cap())

	# Aristas extra dirigidas
	var tries := 0
	while edges.size() < (NODE_COUNT - 1 + EXTRA_EDGES) and tries < 100:
		tries += 1
		var u := randi() % NODE_COUNT
		var v := randi() % NODE_COUNT
		if u == v: continue
		_add_edge_unique(u, v, _rand_cap())

	_update_info()
	queue_redraw()

func _rand_cap() -> int:
	return 5 + int(round(randf_range(0.0, 1.0) * 12.0)) # 5..17 aprox

func _add_edge_unique(u:int, v:int, cap:int) -> void:
	for e in edges:
		if e.u == u and e.v == v:
			return
	edges.append(Edge.new(u, v, cap))

# ---------- Verificar ----------
func _on_check() -> void:
	if s == -1 or t == -1 or s == t:
		_flash_info("Selecciona primero la FUENTE (azul oscuro) y luego el SUMIDERO (verde).")
		return

	# 1) Máximo global entre cualquier par (sin alterar dibujo)
	var best_flow := _global_max_flow_value()

	# 2) Flujo del par elegido y lo dejamos visible
	_reset_flows()
	max_flow = _edmonds_karp(s, t)
	reveal_flow = true

	var is_optimal := (max_flow == best_flow)

	var header := "{0}\n{1}".format([_hud_text(), _algo_brief()])
	var detail := "Flujo máximo con (S={0}, T={1}): {2}".format([s, t, max_flow])
	var compare := "Máximo global posible: {0}".format([best_flow])
	var verdict := (SUCCESS_MSG if is_optimal else "Par no óptimo. Prueba otros nodos como fuente/sumidero.")

	info_cache = "{0}\n\n{1}\n{2}\n\n{3}".format([header, detail, compare, verdict])
	if info_lbl: info_lbl.text = info_cache
	freeze_info = true
	queue_redraw()

# ---------- Utilidades de verificación ----------
func _global_max_flow_value() -> int:
	# Guarda flujos actuales
	var backup: Array[int] = []
	backup.resize(edges.size())
	for i in edges.size():
		backup[i] = edges[i].flow

	var best := 0
	for u in NODE_COUNT:
		for v in NODE_COUNT:
			if u == v: continue
			_reset_flows()
			var f := _edmonds_karp(u, v)
			if f > best:
				best = f

	# Restaura flujos
	for i in edges.size():
		edges[i].flow = backup[i]
	return best

func _flash_info(msg:String) -> void:
	freeze_info = true
	info_cache = "{0}\n{1}".format([_hud_text(), msg])
	if info_lbl: info_lbl.text = info_cache
	await get_tree().create_timer(1.4).timeout
	freeze_info = false
	_update_info()

# ---------- Edmonds–Karp ----------
func _reset_flows() -> void:
	for e in edges:
		e.flow = 0

func _build_residual() -> void:
	G.clear()
	G.resize(NODE_COUNT)
	for i in NODE_COUNT:
		G[i] = []

	for i in edges.size():
		var e := edges[i]
		# forward
		var a := REdge.new()
		a.to = e.v
		a.cap = e.cap - e.flow
		a.rev = (G[e.v] as Array).size()
		a.draw_idx = i
		a.forward = true
		(G[e.u] as Array).append(a)
		# backward
		var b := REdge.new()
		b.to = e.u
		b.cap = e.flow
		b.rev = (G[e.u] as Array).size() - 1
		b.draw_idx = i
		b.forward = false
		(G[e.v] as Array).append(b)

func _edmonds_karp(src:int, sink:int) -> int:
	var flow := 0
	while true:
		_build_residual()

		var parent_v := PackedInt32Array()
		var parent_e := PackedInt32Array()
		parent_v.resize(NODE_COUNT)
		parent_e.resize(NODE_COUNT)
		for i in NODE_COUNT:
			parent_v[i] = -1
			parent_e[i] = -1

		var q: Array[int] = []
		q.append(src)
		parent_v[src] = src

		while q.size() > 0 and parent_v[sink] == -1:
			var u:int = int(q.pop_front())
			var row := G[u] as Array
			for ei in row.size():
				var re := row[ei] as REdge
				if re.cap > 0 and parent_v[re.to] == -1:
					parent_v[re.to] = u
					parent_e[re.to] = ei
					q.append(re.to)
					if re.to == sink:
						break

		if parent_v[sink] == -1:
			break  # no hay más aumentantes

		# capacidad de aumento
		var aug := 1_000_000_000
		var v := sink
		while v != src:
			var u2:int = parent_v[v]
			var re2 := (G[u2] as Array)[parent_e[v]] as REdge
			aug = min(aug, re2.cap)
			v = u2

		# aplicar aumento y reflejar en aristas reales
		v = sink
		while v != src:
			var u3:int = parent_v[v]
			var re3 := (G[u3] as Array)[parent_e[v]] as REdge
			re3.cap -= aug
			var rev := (G[v] as Array)[re3.rev] as REdge
			rev.cap += aug

			var idx := re3.draw_idx
			if re3.forward:
				edges[idx].flow += aug
			else:
				edges[idx].flow -= aug
			v = u3

		flow += aug

	return flow

# ---------- Dibujo ----------
func _has_edge(u:int, v:int) -> bool:
	for ed in edges:
		if ed.u == u and ed.v == v:
			return true
	return false

func _draw() -> void:
	# Aristas base
	for i in edges.size():
		var e := edges[i]
		_draw_arrow(nodes[e.u], nodes[e.v], Color(0.75,0.75,0.9,0.85), EDGE_THICKNESS)

	# Aristas con flujo > 0 (tras verificar)
	if reveal_flow:
		for i in edges.size():
			var e2 := edges[i]
			if e2.flow <= 0: continue
			_draw_arrow(nodes[e2.u], nodes[e2.v], Color(0.2,0.7,1.0,0.95), EDGE_THICKNESS + 1.5)

	# Etiquetas flujo/capacidad (separadas si hay arista inversa)
	for e in edges:
		var a := nodes[e.u]
		var b := nodes[e.v]
		var mid := (a + b) * 0.5

		var offset := Vector2.ZERO
		if _has_edge(e.v, e.u):
			var dir := b - a
			if dir.length() > 0.0:
				var n := Vector2(-dir.y, dir.x).normalized()
				offset = n * 10.0 if e.u < e.v else -n * 10.0
		mid += offset

		var text := "{0}/{1}".format([max(e.flow, 0), e.cap])
		var font := get_theme_default_font()
		var size := 16
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var r := Rect2(mid - ts * 0.5 - Vector2(4, 2), ts + Vector2(8, 6))

		draw_rect(r, Color(0, 0, 0, 0.6), true, 6.0)
		draw_string(font, r.position + Vector2(4, ts.y),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1,1,1))

	# Nodos (S=azul, T=verde)
	for i in nodes.size():
		var inner := NODE_BASE_INNER
		if i == s: inner = SOURCE_COLOR
		elif i == t: inner = SINK_COLOR
		draw_circle(nodes[i], NODE_RADIUS, NODE_BASE_BORDER)
		draw_circle(nodes[i], NODE_RADIUS - 3.0, inner)

		var lbl := str(i)
		var f := get_theme_default_font()
		var sz := 18
		var tsize := f.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
		draw_string(f, nodes[i] - tsize*0.5 + Vector2(0, tsize.y*0.35), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color.BLACK)

func _draw_arrow(a:Vector2, b:Vector2, col:Color, width:float) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 1.0: return
	var u := dir / len
	var start := a + u * (NODE_RADIUS - 2.0)
	var end   := b - u * (NODE_RADIUS + 4.0)
	draw_line(start, end, col, width)
	var n := Vector2(-u.y, u.x)
	var head_len := 10.0
	var p1 := end
	var p2 := end - u * head_len + n * 5.0
	var p3 := end - u * head_len - n * 5.0
	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([col, col, col]))

# ---------- HUD ----------
func _hud_text() -> String:
	return "Nodos: {0}  |  Aristas: {1}  |  Fuente: {2}  |  Sumidero: {3}  |  Flujo: {4}".format([
		NODE_COUNT, edges.size(), (s if s != -1 else -1), (t if t != -1 else -1), max_flow
	])

func _algo_brief() -> String:
	return "Edmonds–Karp: Ford–Fulkerson con BFS. 1er click: FUENTE (azul). 2do: SUMIDERO (verde)."

func _update_info() -> void:
	if not info_lbl: return
	if freeze_info:
		info_lbl.text = info_cache
	else:
		info_lbl.text = "{0}\n{1}".format([_hud_text(), _algo_brief()])

func _clear_all() -> void:
	for e in edges:
		e.flow = 0
	max_flow = 0
	reveal_flow = false
	freeze_info = false
	info_cache = ""
	_update_info()
	queue_redraw()

func _process(_dt: float) -> void:
	_update_info()
