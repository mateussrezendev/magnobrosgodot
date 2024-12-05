extends Area2D

var playerHasKey = false
var playerBody

func _on_body_entered(body):
	if "player" or "player2" in body.name:
		playerBody = body
		if body.hasKey:
			playerHasKey = true
			$opening.play("opening")
			$"../HUD/control/container/key".visible = false
			$StaticBody2D.queue_free()
			$collision.queue_free()
			body.hasKey = false
	if "player3" in body.name:
			playerBody = body
			if body.hasKey:
				playerHasKey = true
				$opening.play("opening")
				$"../HUD/control/container/key".visible = false
				$StaticBody2D.queue_free()
				$collision.queue_free()
				body.hasKey = false
