extends Node2D

@onready var texture = $texture
@onready var area_sign = $area_sign

const lines : Array[String] = [
	"A fábrica está uma bagunça!",
	"Use W, A, S, D para se mover, F para atacar e espaço para pular.",
	"Vamos lá, é hora de agir!",
	"A poluição tomou conta e os robôs de segurança estão corrompidos.",
	"Preciso usar meus braços magnéticos para limpar o caminho e resgatar meu irmão Zap!"
]

func _unhandled_input(event):
	if area_sign.get_overlapping_bodies().size() > 0:
		texture.show()
		if event.is_action_pressed("interact") && !DialogManager.is_message_active:
			texture.hide()
			DialogManager.start_message(global_position, lines)
	else:
		texture.hide()
		if DialogManager.dialog_box != null:
			DialogManager.dialog_box.queue_free()
			DialogManager.is_message_active = false
