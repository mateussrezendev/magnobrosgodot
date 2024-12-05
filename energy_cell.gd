extends Area2D

func _on_body_entered(body):
	body.hasPower = true 
	$anim.play("collect")
	await $collision.call_deferred("queue_free")

func _on_anim_animation_finished():
	queue_free()
