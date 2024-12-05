extends EnemyBase

@onready var spawn_enemy = $"../spawn_enemy"

func _ready():
	spawn_instance = preload("res://actors/fel.tscn")
	spawn_instance_position = spawn_enemy
	can_spawn = true
	anim.animation_finished.connect(kill_air_enemy)
