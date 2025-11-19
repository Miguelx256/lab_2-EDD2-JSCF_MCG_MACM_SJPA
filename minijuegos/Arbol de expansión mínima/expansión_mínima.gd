# lógica para misión Árbol de Expansión Mínima (AEM) usando Grafo/Nodo
extends Control

const Grafo = preload("res://core/Grafo.gd")
const Nodo  = preload("res://core/Nodo.gd")

const NODE_COUNT      : int = 5          # número de nodos
const EXTRA_EDGES     : int = 4          # aristas extra además del árbol base
const NODE_RADIUS     : float = 16.0
const EDGE_THICKNESS  : float = 3.0
const EDGE_HIT_DIST   : float = 10.0     # tolerancia para clicks sobre aristas
const MARGIN          : float = 64.0

enum Algo { KRUSKAL, PRIM }
var current_algo: Algo = Algo.KRUSKAL

# ---------- estructura de una arista para el AEM/dibujo ----------
class Edge:
	var a:int
	var b:int
	var w:int
	var selected:bool = false
	func _init(_a:int,_b:int,_w:int):
		a = _a; b = _b; w = _w

# ---------- Estado gráfico ----------
var nodes_pos : Array[Vector2] = []      # posiciones de nodos (índice compacto 0..N-1)
var edges     : Array[Edge]     = []      # aristas sin duplicados (a<b)

# ---------- Estado de Grafo/Nodo ----------
var g: Grafo
var nodos: Array[Nodo] = []               # lista de Nodos (en orden compacto)
var id2idx: Dictionary = {}               # Nodo.id -> índice compacto 0..N-1

# ---------- Resultado AEM / HUD ----------
var mst_indices : PackedInt32Array = []   # índices de edges del AEM
var mst_cost    : int = 0
var reveal_mst  : bool = false            # mostrar AEM tras verificar
var freeze_info : bool = false
var info_cache  : String = ""

# ---------- UI opcional (si existen en la escena) ----------
@onready var new_btn   : Button = get_node_or_null("NewButton")
@onready var check_btn : Button = get_node_or_null("CheckButton")
@onready var clear_btn : Button = get_node_or_null("ClearButton")
@onready var info_lbl  : Label  = get_node_or_null("InfoLabel")
@onready var next_lvl: Button = $NextLVL


# Popup de selección de algoritmo (creado por código)
var algo_popup: PopupPanel
var prim_btn: Button
var kruskal_btn: Button

func _ready() -> void:
	randomize()
	next_lvl.hide()
	_connect_buttons()
	_create_algo_popup()
	algo_popup.popup_centered()   # elegir algoritmo al inicio

func _connect_buttons() -> void:
	if new_btn:
		new_btn.pressed.connect(func(): algo_popup.popup_centered())  # re-elegir algoritmo
	if check_btn:
		check_btn.pressed.connect(_on_check)
	if clear_btn:
		clear_btn.pressed.connect(_clear_selection)

# ---------- Popup para elegir algoritmo ----------
func _create_algo_popup() -> void:
	algo_popup = PopupPanel.new()
	algo_popup.name = "AlgoPopup"
	algo_popup.size = Vector2(360, 160)
	algo_popup.exclusive = true
	add_child(algo_popup)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	algo_popup.add_child(vb)

	var title := Label.new()
	title.text = "Elige algoritmo para el AEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vb.add_child(title)

	var hb := HBoxContainer.new()
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	kruskal_btn = Button.new()
	kruskal_btn.text = "Usar Kruskal"
	kruskal_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	kruskal_btn.pressed.connect(func():
		current_algo = Algo.KRUSKAL
		algo_popup.hide()
		_new_graph()
	)
	hb.add_child(kruskal_btn)

	prim_btn = Button.new()
	prim_btn.text = "Usar Prim"
	prim_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	prim_btn.pressed.connect(func():
		current_algo = Algo.PRIM
		algo_popup.hide()
		_new_graph()
	)
	hb.add_child(prim_btn)

	var hint := Label.new()
	hint.text = "Para cambiar, pulsa “Generar nuevo grafo”."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1,1,1,0.85)
	vb.add_child(hint)

# ---------- Input ----------
func _gui_input(event: InputEvent) -> void:
	if algo_popup and algo_popup.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var p: Vector2 = mb.position
		_toggle_edge_at_point(p)
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C: _on_check()
			KEY_R: _clear_selection()
			KEY_N: algo_popup.popup_centered()

# ---------- Generación del grafo usando Grafo/Nodo ----------
func _new_graph() -> void:
	# reset
	nodes_pos.clear()
	edges.clear()
	mst_indices = PackedInt32Array()
	mst_cost = 0
	reveal_mst = false
	freeze_info = false
	info_cache = ""

	# Reiniciar id estático para ids 0..N-1
	Nodo.cid = 0

	# 1) Crear N nodos
	g = Grafo.new()
	nodos = []
	for i in NODE_COUNT:
		var nd := Nodo.new(str(i))
		g.agregar_nodo(nd)
		nodos.append(nd)

	# 2) Posiciones en pantalla
	var rect: Vector2 = size
	if rect == Vector2.ZERO:
		rect = get_viewport().get_visible_rect().size
	for i in NODE_COUNT:
		nodes_pos.append(Vector2(
			randf_range(MARGIN, maxf(MARGIN + 1.0, rect.x - MARGIN)),
			randf_range(MARGIN, maxf(MARGIN + 1.0, rect.y - MARGIN))
		))

	# 3) Mapeo Nodo.id -> índice compacto
	id2idx.clear()
	for i in NODE_COUNT:
		id2idx[nodos[i].id] = i

	# 4) Conexiones: arbol aleatorio (para conectividad)
	var order: Array[int] = []
	for i in NODE_COUNT: order.append(i)
	order.shuffle()
	for i in range(1, NODE_COUNT):
		var u := nodos[order[i-1]]
		var v := nodos[order[i]]
		_connect_unique(u, v, false)

	# 5) Aristas extra aleatorias
	var tries := 0
	while _edge_count_undirected() < (NODE_COUNT - 1 + EXTRA_EDGES) and tries < 200:
		tries += 1
		var a := randi() % NODE_COUNT
		var b := randi() % NODE_COUNT
		if a == b: continue
		_connect_unique(nodos[a], nodos[b], true)

	# 6) Derivar arreglo de aristas **sin duplicados** desde el Grafo
	_build_edges_from_grafo()

	# 7) Calcular AEM
	_compute_mst()

	# HUD
	if info_lbl:
		info_lbl.text = "{0}\n{1}".format([_hud_text(), _algo_brief()])
	queue_redraw()

# Calcula un peso por distancia entre posiciones (con ruido opcional)
func _edge_weight_idx(i:int, j:int, noisy:bool=false) -> int:
	var d := nodes_pos[i].distance_to(nodes_pos[j])
	if noisy:
		d *= randf_range(0.8, 1.25)
	return int(round(d / 10.0)) + 1

# Conecta en el Grafo si no existe, asignando peso por distancia
func _connect_unique(n1:Nodo, n2:Nodo, noisy:bool) -> void:
	if not n1.adyacente.has(n2) and not n2.adyacente.has(n1):
		var i:int = int(id2idx[n1.id])
		var j:int = int(id2idx[n2.id])
		var w := _edge_weight_idx(i, j, noisy)
		g.conectar_nodo(n1, n2, w)

# Cuenta pares no dirigidos del Grafo
func _edge_count_undirected() -> int:
	var seen: Dictionary = {}
	var cnt := 0
	for u: Nodo in nodos:
		for v in u.adyacente.keys():
			var iu:int = int(id2idx[u.id])
			var iv:int = int(id2idx[v.id])
			var a:int = (iu if iu < iv else iv)
			var b:int = (iv if iu < iv else iu)
			var key := str(a, ":", b)
			if not seen.has(key):
				seen[key] = true
				cnt += 1
	return cnt

# Toma las conexiones del Grafo y construye edges[] (solo a<b para evitar duplicados)
func _build_edges_from_grafo() -> void:
	edges.clear()
	var seen: Dictionary = {}
	for u: Nodo in nodos:
		for v in u.adyacente.keys():
			var iu:int = int(id2idx[u.id])
			var iv:int = int(id2idx[v.id])
			var a:int = (iu if iu < iv else iv)
			var b:int = (iv if iu < iv else iu)
			var key := str(a, ":", b)
			if seen.has(key): continue
			seen[key] = true
			var w:int = int(round(u.adyacente[v]))
			edges.append(Edge.new(a, b, w))

# ---------- Selector de algoritmo ----------
func _compute_mst() -> void:
	match current_algo:
		Algo.KRUSKAL: _compute_mst_kruskal()
		Algo.PRIM:    _compute_mst_prim()

# ---------- Kruskal ----------
class DSU:
	var p:PackedInt32Array
	var r:PackedInt32Array
	func _init(n:int):
		p = PackedInt32Array()
		r = PackedInt32Array()
		for i in n:
			p.push_back(i)
			r.push_back(0)
	func find(x:int) -> int:
		if p[x] != x:
			p[x] = find(p[x])
		return p[x]
	func unite(a:int, b:int) -> bool:
		a = find(a); b = find(b)
		if a == b: return false
		if r[a] < r[b]:
			var t := a; a = b; b = t
		p[b] = a
		if r[a] == r[b]: r[a] += 1
		return true

func _compute_mst_kruskal() -> void:
	mst_indices = PackedInt32Array()
	mst_cost = 0
	var idxs: Array[int] = []
	for i in edges.size():
		idxs.append(i)
	idxs.sort_custom(func(i:int,j:int): return edges[i].w < edges[j].w)
	var dsu := DSU.new(NODE_COUNT)
	for i in idxs:
		var e := edges[i]
		if dsu.unite(e.a, e.b):
			mst_indices.push_back(i)
			mst_cost += e.w
			if mst_indices.size() == NODE_COUNT - 1:
				break

# ---------- Prim (O(V^2)) ----------
func _build_adjacency() -> Array:
	# adj[u] = Array de diccionarios { "v":int, "idx":int, "w":int }
	var adj: Array = []
	adj.resize(NODE_COUNT)
	for u in NODE_COUNT:
		adj[u] = []
	for i in edges.size():
		var e := edges[i]
		adj[e.a].append({"v": e.b, "idx": i, "w": e.w})
		adj[e.b].append({"v": e.a, "idx": i, "w": e.w})
	return adj

func _compute_mst_prim() -> void:
	mst_indices = PackedInt32Array()
	mst_cost = 0

	var adj := _build_adjacency()

	var in_mst := PackedByteArray()
	in_mst.resize(NODE_COUNT)
	for i in NODE_COUNT:
		in_mst[i] = 0

	var dist := PackedInt32Array()
	dist.resize(NODE_COUNT)
	var parent := PackedInt32Array()  # guarda el padre (nodo)
	parent.resize(NODE_COUNT)
	for v in NODE_COUNT:
		dist[v] = 1_000_000_000
		parent[v] = -1

	var start := 0
	dist[start] = 0

	for _k in NODE_COUNT:
		# elegir u con menor dist que no esté en MST
		var u := -1
		var best := 1_000_000_000
		for v in NODE_COUNT:
			if in_mst[v] == 0 and dist[v] < best:
				best = dist[v]
				u = v
		if u == -1:
			break
		in_mst[u] = 1
		# si tiene padre, añadir arista correspondiente
		if parent[u] != -1:
			for item in adj[u]:
				if item["v"] == parent[u]:
					mst_indices.push_back(item["idx"])
					mst_cost += item["w"]
					break
		# relajar vecinos
		for item in adj[u]:
			var v:int = item["v"]
			var w:int = item["w"]
			if in_mst[v] == 0 and w < dist[v]:
				dist[v] = w
				parent[v] = u

# ---------- Selección y validación ----------
func _toggle_edge_at_point(p:Vector2) -> void:
	var hit := _pick_edge(p)
	if hit == -1: return
	edges[hit].selected = !edges[hit].selected
	if info_lbl:
		info_lbl.text = _hud_text()

func _pick_edge(p:Vector2) -> int:
	var best_idx := -1
	var best_d := 1e9
	for i in edges.size():
		var e := edges[i]
		var a := nodes_pos[e.a]; var b := nodes_pos[e.b]
		var d := _point_segment_distance(p, a, b)
		if d < EDGE_HIT_DIST and d < best_d:
			best_d = d; best_idx = i
	return best_idx

func _point_segment_distance(p:Vector2, a:Vector2, b:Vector2) -> float:
	var ab := b - a
	var t: float = 0.0
	var ab_len2: float = ab.length_squared()
	if ab_len2 > 0.0:
		t = clampf((p - a).dot(ab) / ab_len2, 0.0, 1.0)
	var proj: Vector2 = a + ab * t
	return p.distance_to(proj)

func _clear_selection() -> void:
	for e in edges:
		e.selected = false
	reveal_mst = false
	freeze_info = false
	if info_lbl:
		info_lbl.text = "{0}\n{1}".format([_hud_text(), _algo_brief()])
	queue_redraw()

func _on_check() -> void:
	var res := _validate_selection()
	var status_text := "¡Ganaste, has reeconstruido los servidores!" if res.code == "OK" else "Has fallado la misión..."
	var detail := ""
	
	match res.code:
		"OK":
			detail = "Costo: {0} (óptimo: {1})".format([res.cost, mst_cost])
			next_lvl.show()  # 👈 mostrar botón al ganar
		"NOT_N_MINUS_1":
			detail = "Debes seleccionar exactamente {0} aristas, seleccionaste {1}.".format([NODE_COUNT - 1, res.count])
			next_lvl.hide()
		"DISCONNECTED":
			detail = "Tu selección no conecta todos los nodos (el grafo no es conexo)."
			next_lvl.hide()
		"CYCLE":
			detail = "Tu selección forma ciclos; un árbol no puede tener ciclos."
			next_lvl.hide()
		"NOT_MIN":
			detail = "Tu árbol no es mínimo. Tu costo: {0} | Óptimo: {1}".format([res.cost, mst_cost])
			next_lvl.hide()

	reveal_mst = true
	freeze_info = true
	info_cache = "{0}\n{1}\n\n{2}\n{3}\n\n(Solución mostrada en naranja)".format(
		[_hud_text(), _algo_brief(), status_text, detail]
	)
	if info_lbl:
		info_lbl.text = info_cache
	queue_redraw()


func _validate_selection() -> Dictionary:
	var sel_idxs: Array[int] = []
	for i in edges.size():
		if edges[i].selected:
			sel_idxs.append(i)

	var count := sel_idxs.size()
	if count != NODE_COUNT - 1:
		return {"code": "NOT_N_MINUS_1", "count": count}

	# DSU para conectividad y ciclos
	var dsu := DSU.new(NODE_COUNT)
	for i in sel_idxs:
		var e := edges[i]
		if not dsu.unite(e.a, e.b):
			return {"code": "CYCLE"}

	# Conectividad: todos con el mismo representante
	var root := dsu.find(0)
	for v in NODE_COUNT:
		if dsu.find(v) != root:
			return {"code": "DISCONNECTED"}

	# Costo
	var cost := 0
	for i in sel_idxs:
		cost += edges[i].w

	if cost != mst_cost:
		return {"code": "NOT_MIN", "cost": cost}

	return {"code": "OK", "cost": cost}

func _selected_cost() -> int:
	var c := 0
	for e in edges:
		if e.selected:
			c += e.w
	return c

func _algo_name() -> String:
	return "Kruskal" if current_algo == Algo.KRUSKAL else "Prim"

func _algo_brief() -> String:
	if current_algo == Algo.KRUSKAL:
		return "Kruskal: Ordena aristas por peso y añade las más baratas evitando ciclos hasta conectar todos los nodos."
	else:
		return "Prim: Parte de un nodo y, en cada paso, añade la arista más barata que conecta el árbol con un nodo nuevo."

func _hud_text() -> String:
	return "Algoritmo: {0}  |  Nodos: {1}  |  Aristas: {2}  |  Sel: {3}  |  Costo sel: {4}  |  Costo AEM: {5}".format(
		[_algo_name(), NODE_COUNT, edges.size(), _count_selected(), _selected_cost(), mst_cost]
	)

func _count_selected() -> int:
	var k := 0
	for e in edges:
		if e.selected:
			k += 1
	return k

# ---------- Dibujo ----------
func _draw() -> void:
	# Aristas (fondo)
	for i in edges.size():
		var e := edges[i]
		var a := nodes_pos[e.a]; var b := nodes_pos[e.b]
		draw_line(a, b, Color(0.75,0.75,0.8), EDGE_THICKNESS)

	# Aristas seleccionadas (encima, verde)
	for i in edges.size():
		var e := edges[i]
		if not e.selected: continue
		var a := nodes_pos[e.a]; var b := nodes_pos[e.b]
		draw_line(a, b, Color(0.2,0.8,0.4), EDGE_THICKNESS + 2.0)

	# AEM revelado tras verificar (ámbar), sin duplicar las ya seleccionadas
	if reveal_mst:
		for i in mst_indices:
			var e := edges[i]
			if e.selected: continue
			var a := nodes_pos[e.a]; var b := nodes_pos[e.b]
			draw_line(a, b, Color(1.0, 0.65, 0.0, 0.95), EDGE_THICKNESS + 1.0)

	# Pesos
	for e in edges:
		var mid := (nodes_pos[e.a] + nodes_pos[e.b]) * 0.5
		var bg := Color(0,0,0,0.6)
		var fg := Color(1,1,1)
		var text := str(e.w)
		var font := get_theme_default_font()
		var size := 16
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var r := Rect2(mid - ts*0.5 - Vector2(4,2), ts + Vector2(8,6))
		draw_rect(r, bg, true, 6.0)
		draw_string(font, r.position + Vector2(4, ts.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, fg)

	# Nodos
	for i in nodes_pos.size():
		draw_circle(nodes_pos[i], NODE_RADIUS, Color(0.15,0.2,0.28))
		draw_circle(nodes_pos[i], NODE_RADIUS-3.0, Color(0.9,0.95,1.0))
		var label_text := str(i)
		var f := get_theme_default_font()
		var s := 18
		var tsize := f.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s)
		draw_string(f, nodes_pos[i] - tsize*0.5 + Vector2(0, tsize.y*0.35), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color.BLACK)

func _process(_dt: float) -> void:
	if not info_lbl:
		return
	if freeze_info:
		info_lbl.text = info_cache
	else:
		info_lbl.text = "{0}\n{1}".format([_hud_text(), _algo_brief()])


func _on_next_lvl_button_down() -> void:
	get_tree().change_scene_to_file("res://minijuegos/Flujo maximo/Flujo maximo.tscn")
