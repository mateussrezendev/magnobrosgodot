extends CharacterBody2D

const SPEED = 200.0 
const AIR_FRICTION := 0.5

const COIN_SCENE := preload("res://prefabs/coin_rigid.tscn")
const LIFE_SCENE := preload("res://prefabs/health_battery_rigid.tscn")
const ACID_SMOKE := preload("res://prefabs/acid_smoke.tscn")
const zip := preload("res://actors/player.tscn")
const zap := preload("res://actors/player2.tscn")
var hasKey := false
var died := false
var is_jumping := false
var is_hurted := false
var knockback_vector := Vector2.ZERO
var knockback_power := 10
var direction
var punch = false

signal two_players

@export var jump_height := 64
@export var max_time_to_peak := 0.5

var jump_velocity
var gravity
var fall_gravity
var enemies_in_range: Array = []
var attacking : bool

@onready var animation := $anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D
@onready var jump_sfx = $jump_sfx as AudioStreamPlayer
@onready var destroy_sfx = preload("res://sounds/destroy_sfx.tscn")
@onready var player_start_position = $"../player_start_position"

signal player_has_died()

func _ready():
	jump_velocity = (jump_height * 2) / max_time_to_peak
	gravity = (jump_height * 2) / pow(max_time_to_peak, 2)
	fall_gravity = gravity * 2

func separate_players():
	var player1 = zip.instantiate()
	var player2 = zap.instantiate()
	get_parent().add_child(player1)
	get_parent().add_child(player2)
	player1.global_position = global_position - Vector2(10, 0)
	player2.global_position = global_position + Vector2(10, 0)
	queue_free()
	two_players.emit()

func attack():
	punch = true
	for enemy in enemies_in_range:
		enemy.anim.play("hurt")
		enemy.stop_movement()

func _physics_process(delta):
	if Input.is_action_just_pressed("separate"):
		separate_players()
		
	if not is_on_floor():
		velocity.x = 0 
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_velocity
		is_jumping = true
		jump_sfx.play()
	elif is_on_floor():
		is_jumping = false
		
	if velocity.y > 0 or not Input.is_action_pressed("jump"):
		velocity.y += fall_gravity * delta
	else:
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("punch"):
		$anim.play("punch")
		attack()

	direction = Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = lerp(velocity.x, direction * SPEED, AIR_FRICTION)
		animation.scale.x = direction
		$attack/collision.position.x *= direction
		if direction > 0:
			$attack/collision.position.x = 14
		if direction < 0:
			$attack/collision.position.x = -14
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
	
	_set_state()
	move_and_slide()
	
	for platforms in get_slide_collision_count():
		var collision = get_slide_collision(platforms)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)
	
	
func _on_hurtbox_body_entered(body: Node2D) -> void:
	var knockback = Vector2((global_position.x - body.global_position.x) * knockback_power, -200)
	take_damage(knockback)

	if body.is_in_group("bullet"):
		body.queue_free()

func follow_camera(camera):
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path

func take_damage(knockback_force := Vector2.ZERO, duration := 0.25):
	if died:
		return
	if Globals.player_life > 0:
		Globals.player_life -= 1
	else:
		death()
	
	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force
		
		var knockback_tween := get_tree().create_tween()
		knockback_tween.parallel().tween_property(self, "knockback_vector", Vector2.ZERO, duration)
		animation.modulate = Color(1,0,0,1)
		knockback_tween.parallel().tween_property(animation, "modulate", Color(1,1,1,1), duration)
	
	lose_coins()
	
	is_hurted = true
	await get_tree().create_timer(.5).timeout
	is_hurted = false

func _set_state():
	if died:
		return
	if punch:
		return

	var state = "idle"
	if !is_on_floor():
		state = "jump"
	elif direction != 0:
		state = "walk"
	if is_hurted:
		state = "hurt"
	
	if animation.name != state:
		animation.play(state)

func _on_head_collider_body_entered(body):
	if body.has_method("break_sprite"):
		body.hitpoints -= 1
		if body.hitpoints < 0:
			body.break_sprite()
			play_destroy_sfx()
		else:
			body.animation_player.play("hit_flash")
			body.hit_block.play()
			body.create_life()
			body.create_coin()

func death():
	if Globals.player_life <= 0 and not died:
		died = true
		$anim.play("death")
		$collision.set_deferred("disabled", true)
		await $anim.animation_finished

		emit_signal("player_has_died")
		queue_free()

func play_destroy_sfx():
	var sound_sfx = destroy_sfx.instantiate()
	get_parent().add_child(sound_sfx)
	sound_sfx.play()
	await sound_sfx.finished
	sound_sfx.queue_free()

func lose_coins():
	var lost_coins : int = min(Globals.coins, 5)
	$collision.set_deferred("disabled", true)
	Globals.coins -= lost_coins
	for i in lost_coins:
		var coin = COIN_SCENE.instantiate()
		get_parent().call_deferred("add_child", coin)
		coin.global_position = global_position
		coin.apply_impulse(Vector2(randi_range(-100,100),-250))
	await get_tree().create_timer(0.5).timeout
	$collision.set_deferred("disabled", false)

func handle_death_zone():
	var acid_smoke = ACID_SMOKE.instantiate()
	acid_smoke.global_position = global_position
	get_parent().add_child(acid_smoke)

	if Globals.player_life > 0:
		Globals.player_life -= 1
		visible = false
		set_physics_process(false)
		await get_tree().create_timer(1.0).timeout
		Globals.respawn_player()
		visible = true
		set_physics_process(true)
	else:
		visible = false
		await get_tree().create_timer(0.5).timeout
		player_has_died.emit()


func _on_anim_animation_finished():
	if $anim.animation == "punch":
		punch = false

func _on_attack_body_entered(body):
	enemies_in_range.append(body)


func _on_attack_body_exited(body):
	enemies_in_range.erase(body)
