extends Node2D

var grafo
var posiciones: Dictionary = {}
var radio_nodo := 24

var font: Font = ThemeDB.fallback_font


# ---------------------------------------------------------
# Recibir grafo
# ---------------------------------------------------------
func set_grafo(_grafo) -> void:
	grafo = _grafo
	_asignar_posiciones()
	queue_redraw()


# ---------------------------------------------------------
# Posiciones en círculo
# ---------------------------------------------------------
func _asignar_posiciones() -> void:
	var total: int = grafo.lista_adyacencia.size()
	var centro := Vector2(400, 250)
	var radio := 150.0

	for i in range(total):
		var ang := TAU * float(i) / float(total)
		posiciones[grafo.lista_adyacencia[i]] = centro + Vector2(cos(ang), sin(ang)) * radio


# ---------------------------------------------------------
# Dibujar grafo completo
# ---------------------------------------------------------
func _draw() -> void:
	if grafo == null:
		return

	# ==========================
	# DIBUJAR ARISTAS
	# ==========================
	for nodo in grafo.lista_adyacencia:
		var p1: Vector2 = posiciones[nodo]

		for vecino in nodo.adyacente.keys():
			var p2: Vector2 = posiciones[vecino]
			var peso: float = nodo.adyacente[vecino]

			draw_line(p1, p2, Color.WHITE, 2)

			var mid := (p1 + p2) * 0.5
			var etiqueta := str(round(peso * 10.0) / 10.0)

			draw_string(
				font,
				mid,
				etiqueta,
				Color.YELLOW,
				16
			)

	# ==========================
	# DIBUJAR NODOS
	# ==========================
	for nodo in grafo.lista_adyacencia:
		var pos: Vector2 = posiciones[nodo]

		draw_circle(pos, radio_nodo, Color.DODGER_BLUE)

		draw_string(
			font,
			pos + Vector2(-6, 6),
			nodo.dato,
			Color.BLACK,
			16
		)
