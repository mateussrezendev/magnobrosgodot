extends RigidBody2D

func _on_health_battery_tree_exited():
	queue_free()
