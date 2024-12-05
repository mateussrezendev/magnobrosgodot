extends CharacterBody2D


const SPEED = 200.0 
const AIR_FRICTION := 0.5

const COIN_SCENE := preload("res://prefabs/coin_rigid.tscn")
const LIFE_SCENE := preload("res://prefabs/health_battery_rigid.tscn")
const ACID_SMOKE := preload("res://prefabs/acid_smoke.tscn")
const BULLET_SCENE = preload("res://prefabs/zip_bullet.tscn")
var hasKey := false
var hasPower := false
var died := false
var is_jumping := false
var is_hurted := false
var knockback_vector := Vector2.ZERO
var knockback_power := 10
var direction
var punch = false
var special_power = false
var uppercut = false
var on_ladder: bool = false
var is_shooting := false

@export var jump_height := 64
@export var max_time_to_peak := 0.5

var jump_velocity
var gravity
var fall_gravity
var enemies_in_range: Array = []
var enemies_in_range2   : Array = []
var attacking : bool

@onready var animation := $anim as AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D
@onready var jump_sfx = $jump_sfx as AudioStreamPlayer
@onready var destroy_sfx = preload("res://sounds/destroy_sfx.tscn")
@onready var player_start_position = $"../player_start_position"
@onready var bullet_position = $bullet_position
@onready var shoot_cooldown = $shoot_cooldown

signal player_has_died()

func _ready():
	jump_velocity = (jump_height * 2) / max_time_to_peak
	gravity = (jump_height * 2) / pow(max_time_to_peak, 2)
	fall_gravity = gravity * 2

func attack():
	$anim.play("punch")
	punch = true
	special_power = false
	uppercut = false
	for enemy in enemies_in_range:
		enemy.anim.play("hurt")
		enemy.stop_movement()

func special():
	$anim.play("special")
	special_power = true
	uppercut = false
	punch = false
	for enemy in enemies_in_range:
		enemy.anim.play("hurt")
		enemy.stop_movement()
func Uppercut():
	uppercut = true
	special_power = false
	punch = false
	$anim.play("uppercut")
	for enemy in enemies_in_range:
		enemy.anim.play("hurt")
		enemy.stop_movement()

func _physics_process(delta):

	if not is_on_floor() and !on_ladder:
		velocity.x = 0 
	if uppercut == true or punch == true or special_power == true:
		$hurtbox/collision.set_deferred("disabled", true)
	if uppercut == false and punch == false and special_power == false:
		$hurtbox/collision.set_deferred("disabled", false)
	if on_ladder:
		if Input.is_action_pressed("down"):
			velocity.y = SPEED * delta * 10
		elif Input.is_action_pressed("up"):
			velocity.y = -SPEED * delta * 10
		else:
			velocity.y = 0

	if Input.is_action_just_pressed("jump") and is_on_floor() and !on_ladder:
		velocity.y = -jump_velocity
		is_jumping = true
		jump_sfx.play()
	elif is_on_floor() and !on_ladder:
		is_jumping = false
		
	if velocity.y > 0 or not Input.is_action_pressed("jump") and not on_ladder:
		velocity.y += fall_gravity * delta
	elif !on_ladder:
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("punch"):
		attack()
	
	elif is_on_floor() and !on_ladder:
		is_jumping = false
		
	if Input.is_action_just_pressed("upper") and is_on_floor() and !on_ladder:
		velocity.y = -jump_velocity
		is_jumping = true
		Uppercut()

	direction = Input.get_axis("left", "right")
	
	if Input.is_action_pressed("left"):
		if sign(bullet_position.position.x) == 1:
			bullet_position.position.x *= -1
	
	if Input.is_action_pressed("right"):
		if sign(bullet_position.position.x) == -1:
			bullet_position.position.x *= -1
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
	
	if Input.is_action_just_pressed("shoot") and hasPower == true:
		shoot()
	
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
	if special_power:
		return
	if uppercut:
		return
	if is_shooting:
		return
	var state = "idle"
	if !is_on_floor() and !is_shooting:
		state = "jump"
	elif direction != 0  and !is_shooting:
		state = "walk"
	if is_hurted:
		state = "hurt"
	if on_ladder:
		state = "stair"
	
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
			body.create_special()

func death():
	if Globals.player_life <= 0 and not died:
		died = true
		$anim.play("death")
		$collision.set_deferred("disabled", true)
		await $anim.animation_finished

		emit_signal("player_has_died")
		queue_free()

func shoot():
	$anim.play("shoot")
	is_shooting = true
	if shoot_cooldown.is_stopped():
		await $anim.animation_finished
		shoot_bullet()
		is_shooting = false

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
		uppercut = false
		special_power = false
		punch = false
	if $anim.animation == "uppercut":
		punch = false
		uppercut = false
		special_power = false
	if $anim.animation == "special":
		special_power = false
		punch = false
		uppercut = false


func _on_ladder_body_entered(body: Node2D) -> void:
	if "player" in body.name:
		on_ladder = true

func _on_ladder_body_exited(body: Node2D) -> void:
	if "player" in body.name:
		on_ladder = false
	
func _on_area_sign_body_entered(_body):
	$"../warning_sign/sprite".frame = 1
	if $"../warning_sign/sprite".frame == 1:
		$"../warning_sign/light".visible = true
	
func _on_area_sign_body_exited(_body):
	$"../warning_sign/sprite".frame = 0
	if $"../warning_sign/sprite".frame == 0:
		$"../warning_sign/light".visible = false


func _on_attack_body_entered(body):
	enemies_in_range.append(body)


func _on_attack_body_exited(body):
	enemies_in_range.erase(body)


func _on_special_body_entered(body):
	enemies_in_range2.append(body)


func _on_special_body_exited(body):
	enemies_in_range2.erase(body)

func shoot_bullet():
	var bullet_instance = BULLET_SCENE.instantiate()
	if sign(bullet_position.position.x) == 1:
		bullet_instance.set_direction(1)
	else:
		bullet_instance.set_direction(-1)
		
	add_sibling(bullet_instance)
	bullet_instance.global_position = bullet_position.global_position
	shoot_cooldown.start()
