extends Area2D

func _on_body_entered(body):
	if "player" in body.name or "player2" in body.name:
		body.hasKey = true
		queue_free()
		call_deferred("_show_key")

func _show_key():
	var key_icon = $"../HUD/control/container/key"
	if key_icon:
		key_icon.visible = true
