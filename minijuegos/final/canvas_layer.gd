# canvas_layer.gd (ahora sí sirve)
extends Node2D

var nodos: Array = []
var aristas: Array = []
var radio_nodo: float = 20

var font

func _ready():
	font = ThemeDB.fallback_font

func _draw():
	# Dibujar aristas
	for a in aristas:
		var p1 = nodos[a[0]]
		var p2 = nodos[a[1]]

		draw_line(p1, p2, Color.WHITE, 2)

		# Peso en el medio
		var mid = (p1 + p2) * 0.5
		draw_string(
			font,
			mid,
			str(a[2]),
			0,
			-1,
			20,
			Color.YELLOW
		)

	# Dibujar nodos
	for i in range(nodos.size()):
		draw_circle(nodos[i], radio_nodo, Color.RED)
		draw_string(
			font,
			nodos[i] + Vector2(-5, -radio_nodo - 5),
			str(i),
			0,
			-1,
			20,
			Color.WHITE
		)

func actualizar_grafo(nodos_array: Array, aristas_array: Array):
	nodos = nodos_array.duplicate()
	aristas = aristas_array.duplicate()
	queue_redraw()
