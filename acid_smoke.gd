extends AnimatedSprite2D

@onready var audio_player = $audio

func _ready():
	audio_player.play()

func _on_animation_finished():
	queue_free()

