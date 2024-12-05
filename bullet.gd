extends CharacterBody2D

var move_speed := 100.0
var direction := 1

func _process(delta):
	position.x += move_speed * direction * delta

func set_direction(dir):
	direction = dir
	if dir < 0:
		$anim.flip_h = true
	else:
		$anim.flip_h = false
