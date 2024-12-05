extends Node2D

var collision_type: String = "escada"

@onready var collision = $area2d/collision


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.em_escada = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.em_escada = false
