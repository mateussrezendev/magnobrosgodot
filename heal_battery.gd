extends Area2D

var life := 1 

func _on_body_entered(_body):
	$anim.play("collect")
	await $collision.call_deferred("queue_free")
	Globals.player_life += life

func _on_anim_animation_finished():
	queue_free()


func _on_health_battery_rigid_tree_exited():
	queue_free()
