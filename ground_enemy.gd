extends EnemyBase
@onready var collision = $hitbox/collision

func _ready():
	wall_detector = $wall_detector
	ground_detector = $ground_detector
	sprite = $sprite
	anim.animation_finished.connect(kill_ground_enemy)

func _physics_process(delta):
	_apply_gravity(delta)
	movement(delta)
	flip_direction()

func _on_anim_animation_started(anim_name):
	if anim_name == "hurt":
		$PointLight2D.set_deferred("disabled", true)
		collision.set_deferred("disabled", true)
		$hitbox.set_deferred("disabled", true)
		$collision.set_deferred("disabled", true)
