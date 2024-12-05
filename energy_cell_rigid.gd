extends RigidBody2D


func _on_energy_cell_tree_exited():
	queue_free()
