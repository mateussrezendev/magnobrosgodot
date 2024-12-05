extends CharacterBody2D 

const BOMB := preload("res://prefabs/bomb.tscn")
const MISSILE := preload("res://prefabs/missile.tscn")
const KEY := preload("res://prefabs/key.tscn")
const SPEED = 5000.0
var direction = -1
var is_alive := true
@onready var wall_detector = $wall_detector
@onready var sprite = $sprite
@onready var missile_point = %missile_point
@onready var bomb_point = %bomb_point
@onready var anim_tree = $anim_tree
@onready var state_machine = anim_tree["parameters/playback"]

var turn_count := 0
var missile_count := 0
var bomb_count := 0
var can_launch_missile := true
var can_launch_bomb := true
var player_hit := false
var is_dead := false

func _ready():
	set_physics_process(false)
var health_points := 3
var damage_processed := false

func _physics_process(delta):
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
		turn_count += 1
	if is_alive:
		match state_machine.get_current_node():
			"moving":
				if !is_dead:
					reset_vulnerability_state()
					$attack/collision.set_deferred("disabled", false)
					
					$hurtbox/collision.set_deferred("disabled", true) 
					if direction == 1:
						velocity.x = SPEED * delta
						sprite.flip_h = true
					else:
						velocity.x = -SPEED * delta
						sprite.flip_h = false
			"missile_attack":
				velocity.x = 0
				await get_tree().create_timer(2.0).timeout
				if can_launch_missile:
					launch_missile()
					can_launch_missile = false
			"hide_bomb":
				velocity.x = 0
				await get_tree().create_timer(2.0).timeout
				if can_launch_bomb:
					throw_bomb()
					can_launch_bomb = false
			"vunerable":
				$attack/collision.set_deferred("disabled", true)
				damage_processed = true
				can_launch_missile = false
				can_launch_bomb = false
				velocity.x = 0
				await get_tree().create_timer(2.0).timeout
				player_hit = false
				$hurtbox/collision.set_deferred("disabled", false)
				
				anim_tree.set("parameters/conditions/is_vunerable", false)
				if missile_count < 4:
					anim_tree.set("parameters/conditions/time_missile", true)
				elif bomb_count < 3:
					anim_tree.set("parameters/conditions/time_bomb", true)
	if turn_count <= 2:
		anim_tree.set("parameters/conditions/can_move", true)
		anim_tree.set("parameters/conditions/time_missile", false)
	elif missile_count >= 4:
		anim_tree.set("parameters/conditions/time_bomb", true)
		missile_count = 0
	elif bomb_count >= 3:
		anim_tree.set("parameters/conditions/is_vunerable", true)
		bomb_count = 0
	else:
		anim_tree.set("parameters/conditions/can_move", false)
		anim_tree.set("parameters/conditions/is_vunerable", false)
		anim_tree.set("parameters/conditions/time_bomb", false)
		anim_tree.set("parameters/conditions/time_missile", true)
	move_and_slide()
	
func apply_damage():
	if health_points > 0:
		health_points -= 1
	if health_points <= 0:
		is_dead = true
		is_alive = false
		$anim_player.play("death")
		await $anim_player.animation_finished
		queue_free()
		call_deferred("_spawn_key")
		
	damage_processed = true


func _spawn_key():
	var key = KEY.instantiate()
	get_parent().add_child(key)
	key.global_position = global_position + Vector2(20, -20)

func reset_vulnerability_state():
	damage_processed = false
	
func throw_bomb():
	if bomb_count <= 3:
		var bomb_instance = BOMB.instantiate()
		add_sibling(bomb_instance)
		bomb_instance.global_position = bomb_point.global_position
		bomb_instance.apply_impulse(Vector2(randi_range(direction * 30, direction * 200), randi_range(-200,-400)))
		$bomb_cooldown.start()
		bomb_count += 1

func launch_missile():
	if missile_count <= 4:
		var missile_instance = MISSILE.instantiate()
		add_sibling(missile_instance)
		missile_instance.global_position = missile_point.global_position
		missile_instance.set_direction(direction)
		$missile_cooldown.start()
		missile_count += 1

func _on_bomb_cooldown_timeout():
	can_launch_bomb = true

func _on_missile_cooldown_timeout():
	can_launch_missile = true

func _on_player_detector_body_entered(_body):
	set_physics_process(true)

func _on_visible_on_screen_enabler_2d_screen_entered():
	set_physics_process(true)


func _on_hurtbox_body_entered(body):
	apply_damage()
	body.velocity = Vector2(50, -300)
	player_hit = true
	turn_count = 0 


func _on_attack_body_entered(body):
	if body.name == "player":
		body.take_damage(Vector2((global_position.x - body.global_position.x) * -10, -200))
