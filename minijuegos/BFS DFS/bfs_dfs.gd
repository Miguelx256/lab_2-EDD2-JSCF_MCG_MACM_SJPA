# logica para mision BFS DFS
extends Node2D
@export var nombre: String = ""
@onready var label = $Label
@onready var color_rect = $ColorRect

func _ready():
	label.text = nombre

func marcar_visitado():
	color_rect.color = Color(0.1, 0.8, 0.3)

func reiniciar_color():
	color_rect.color = Color(0.4, 0.4, 0.4)
func marcar_infectado():
	color_rect.color = Color(1, 0.2, 0.2)  # Rojo
