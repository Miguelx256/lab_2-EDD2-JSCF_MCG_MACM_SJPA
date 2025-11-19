class_name NodoVisual
extends Node2D

var nodo: Nodo
var posicion_inicial: Vector2 = Vector2.ZERO
@export var radius := 20.0

var is_dragging := false
var seleccionado := false

var label: Label
var area: Area2D


func _ready():
	# Aplicar posición inicial si es distinta a cero
	if posicion_inicial != Vector2.ZERO:
		position = posicion_inicial

	# Referencia al Area2D
	area = $Area2D

	# Ajustar tamaño del CollisionShape2D
	var shape := CircleShape2D.new()
	shape.radius = radius
	$Area2D/CollisionShape2D.shape = shape

	# Label mostrando el ID del nodo
	label = $Label
	if nodo != null:
		label.text = str(nodo.id)
	else:
		label.text = "?"

	queue_redraw()


func _draw():
	# Cambiar color si está seleccionado
	var color := Color(1, 0.4, 0.4) if seleccionado else Color(0.2, 0.6, 1.0)

	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius - 3, Color(1, 1, 1))


func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:

			# alternar selección
			seleccionado = !seleccionado
			queue_redraw()

			# permitir arrastrar
			is_dragging = true
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and not event.pressed:
		is_dragging = false


func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position()
		get_parent().queue_redraw()
