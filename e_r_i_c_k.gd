extends EnemyBase

@onready var collision = $hitbox/collision
const KEY = preload("res://prefabs/key2.tscn")
@onready var arena_area = $"../../arena_area"
@onready var player = $"../../player"

var occupied := false as bool
var is_on_player_right = true
var being_hurt := false
var health_points := 10
var attack1 = false
enum EnemyState { PATROL, ATTACK, HURT, DEATH }
var current_state = EnemyState.PATROL
var player_in_range: Array = []
func _ready():
	sprite = $sprite

func _physics_process(delta):
	if sprite.flip_h:
		$range/collision.position.x = 110
		$damage_area/collision.position.x = 53
	else:
		$range/collision.position.x = -110
		$damage_area/collision.position.x = -53
	if !occupied:
		if !being_hurt && !arena_area.first_entering:
			match current_state:
				EnemyState.PATROL: patrol_state()
				EnemyState.ATTACK: attack_state()
		_apply_gravity(delta)
		movement(delta)
func patrol_state():
	anim.play("idle")
	if global_position.direction_to(player.global_position).x < 0:
		direction = -1
		is_on_player_right = true
		
	elif global_position.direction_to(player.global_position).x > 0:
		direction = 1
		is_on_player_right = false
	if velocity.x > 0:
		$sprite.flip_h = true
	elif velocity.x < 0:
		$sprite.flip_h = false

func teleport():
	var tp_distance
	if is_on_player_right:
		tp_distance = 100
	else:
		tp_distance = -100
	if arena_area.player_inside:
		global_position.x = player.global_position.x - tp_distance
		sprite.flip_h = !sprite.flip_h
		anim.play("appearing")
		await anim.animation_finished
	being_hurt = false
	$range/collision.shape.size.x = 218
	SPEED = 1700
func attack_state():
	anim.play("attack1")

func hurt_state():
	occupied = false
	being_hurt = true
	SPEED = 0
	$range/collision.shape.size.x = 0
	if !arena_area.player_inside:
		anim.play("hurt")
		await anim.animation_finished
		being_hurt = false
	else:
		anim.play("death")
		await anim.animation_finished
	if health_points > 0:
		health_points -= 1
		teleport()
	else:
		_change_state(EnemyState.DEATH)
		death_state()
	_change_state(EnemyState.PATROL)
		
func death_state():
	$hitbox/collision.set_deferred("disabled", true)
	anim.play("death")
	await anim.animation_finished
	queue_free()
	var key = KEY.instantiate()
	get_parent().add_child(key)
	key.global_position = global_position

func _change_state(state):
	if current_state == EnemyState.DEATH:
		return
	current_state = state

func _on_hitbox_body_entered(_body):
	if current_state != EnemyState.DEATH:
		_change_state(EnemyState.HURT)
		hurt_state()
func _on_attack_1_body_entered(body):
	if body.name == "player" or body.name == "player2" or body.name == "player3":
		body.velocity.y = -body.jump_velocity
		body.take_damage(Vector2.ZERO, 0.25)

func _on_attack_1_body_exited(_body):
	_change_state(EnemyState.PATROL)

func _on_range_body_entered(_body):
	if anim.is_playing()and anim.current_animation == "appearing" or anim.is_playing()and anim.current_animation == "death":
			await anim.animation_finished
	occupied = true
	anim.play("attack1")
	

func _on_range_body_exited(_body):
	occupied = false


func _on_damage_area_body_entered(body):
	if body.name == "player":
		body.take_damage(Vector2((global_position.x - body.global_position.x) * -10, -200))
