extends Area2D

@onready var health_bar = $"../CanvasLayer/health_bar"
@onready var door_opened_boss = $"../door_opened_boss"
var first_entering := true as bool
var player_inside := false as bool

func _on_body_entered(_body):
	if first_entering:
		health_bar.visible = true
		door_opened_boss.get_child(1).shape.size.y = 60
		door_opened_boss.get_child(1).position.y = 0.333
		door_opened_boss.get_child(0).play("closing")
		first_entering = false
	player_inside = true


func _on_body_exited(_body):
	player_inside = false
