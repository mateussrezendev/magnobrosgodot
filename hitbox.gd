extends Area2D

func _on_body_entered(body):
	if body.name == "player" or body.name == "player2" or body.name == "player3":
		body.velocity.y = -body.jump_velocity
		get_parent().stop_movement()
		get_parent().anim.play("hurt")

func _on_area_entered(area):
	if area.is_in_group("bullets"):
		get_parent().hurt_state()
		area.queue_free()
