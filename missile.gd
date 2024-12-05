extends AnimatableBody2D

const SPEED := 100.0
const EXPLOSION := preload("res://prefabs/explosion.tscn")
const player := preload("res://actors/player.tscn")

@onready var sprite = $sprite
@onready var missile_collision = $missile_collision
@onready var collision = $collision_detection/collision

var velocity := Vector2.ZERO
var direction

func _process(delta):
	velocity.x = SPEED * direction * delta
	
	move_and_collide(velocity)

func set_direction(dir):
	direction = dir
	if direction == 1:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _on_collision_detection_body_entered(body):
	visible = false
	var explosion_instance = EXPLOSION.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_position = global_position
	missile_collision.set_deferred("disabled", true)
	collision.set_deferred("disabled", true)
	if body.name == "player":
		body.take_damage(Vector2((global_position.x - body.global_position.x) * -10, -200))
		
	await explosion_instance.animation_finished
	queue_free()
