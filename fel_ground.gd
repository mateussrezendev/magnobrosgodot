extends EnemyBase

func _ready():
	wall_detector = $wall_detector
	anim.animation_finished.connect(kill_air_enemy)
	
func _physics_process(delta):
	_apply_gravity(delta)
	movement(delta)

func stop_movement():
	pass
