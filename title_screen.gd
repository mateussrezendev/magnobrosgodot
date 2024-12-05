extends Control

func _ready():
	Globals.coins = 0
	Globals.score = 0
	Globals.player_life = 3 
func _process(delta):
	if Input.is_action_just_pressed("start"):
		get_tree().change_scene_to_file("res://levels/world_01.tscn")
		
func _on_start_btn_pressed():
	get_tree().change_scene_to_file("res://levels/world_01.tscn")

func _on_options_btn_pressed():
	pass

func _on_quit_btn_pressed():
	get_tree().quit()
