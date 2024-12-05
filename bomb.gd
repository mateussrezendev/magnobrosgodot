extends RigidBody2D

const EXPLOSION = preload("res://prefabs/explosion.tscn")
const player := preload("res://actors/player.tscn")
@onready var collision = $collision

func _on_body_entered(body):
	if body.name == "player":
		body.take_damage(Vector2((global_position.x - body.global_position.x) * -10, -200))
	visible = false
	var explosion_instance = EXPLOSION.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_position = global_position
	collision.set_deferred("disabled", true)
	await explosion_instance.animation_finished
	queue_free()
