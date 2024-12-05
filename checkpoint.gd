extends Area2D

var is_active = false
@onready var anim = $anim
@onready var marker_2d = $Marker2D

func _on_body_entered(body):
	if is_active:
		return
	
	if body.name == "player" or body.name == "player2" or body.name == "player3":
		activate_checkpoint()

func activate_checkpoint():
	Globals.current_checkpoint = marker_2d
	anim.play("raising")
	is_active = true

func _on_anim_animation_finished():
	if anim.animation == "raising":
		anim.play("checked")
