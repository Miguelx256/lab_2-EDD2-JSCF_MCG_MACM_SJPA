extends Node2D

var nodo_id: int = 0
var radio: float = 20
var seleccionado: bool = false
var color: Color

# Fuente interna de Godot
var font

signal nodo_seleccionado(nodo_id)

func _ready():
	font = ThemeDB.fallback_font

func _draw():
	color = Color.GREEN if seleccionado else Color.RED
	draw_circle(Vector2.ZERO, radio, color)

	draw_string(
		font,
		Vector2(-8, -radio - 5),
		str(nodo_id),
		0,      # Alineación
		-1,     # Ancho
		22,     # Tamaño
		Color.WHITE
	)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = to_local(event.position)
		if mouse_pos.length() <= radio:
			seleccionado = not seleccionado
			emit_signal("nodo_seleccionado", nodo_id)
			queue_redraw()
