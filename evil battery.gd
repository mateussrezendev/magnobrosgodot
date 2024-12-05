extends CharacterBody2D

const POWER = preload("res://prefabs/power.tscn")
var move_speed := 50.0
var direction := 1
var health_points := 3
var is_alive := true
@onready var sprite = $sprite
@onready var anim = $anim
@onready var power_spawn_point = $power_spawn_point
@onready var ground_detector = $ground_detector
@onready var player_detector = $player_detector

enum EnemyState {PATROL, ATTACK, HURT}
var current_state = EnemyState.PATROL
@export var target : CharacterBody2D

func _physics_process(_delta):
	if is_alive:
		match(current_state):
			EnemyState.PATROL : patrol_state()
			EnemyState.ATTACK : attack_state()
		

func patrol_state():
	anim.play("running")
	if is_on_wall():
		flip_enemy()

	if not ground_detector.is_colliding():
		flip_enemy()

	velocity.x = move_speed * direction
	
	if player_detector.is_colliding():
		_change_state(EnemyState.ATTACK)

	move_and_slide()

func attack_state():
	anim.play("shooting")
	if not player_detector.is_colliding():
			_change_state(EnemyState.PATROL)

func hurt_state():
	anim.play("hurt")
	await get_tree().create_timer(0.3).timeout
	_change_state(EnemyState.PATROL)
	if health_points > 0:
		health_points -= 1
	else:
		is_alive = false
		$hitbox/collision.set_deferred("disabled", true)
		$collision.set_deferred("disabled", true)
		anim.play("death")
		await anim.animation_finished
		queue_free()

func _change_state(state):
	current_state = state

func flip_enemy():
	direction *= -1
	sprite.scale.x *= -1
	player_detector.scale.x *= -1
	power_spawn_point.position.x *= -1
	
func spawn_power():
	var new_power = POWER.instantiate()
	if direction == 1:
		new_power.set_direction(1)
	else:
		new_power.set_direction(-1)
	
	add_sibling(new_power)
	new_power.global_position = power_spawn_point.global_position


func _on_hitbox_body_entered(_body):
	_change_state(EnemyState.HURT)
	hurt_state()

func stop_movement():
	pass
