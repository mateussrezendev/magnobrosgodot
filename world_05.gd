extends Node2D

@onready var player := $player3 as CharacterBody2D
@onready var player_scene = preload("res://actors/player3.tscn")
@onready var camera := $camera as Camera2D
@onready var control = $HUD/control
@onready var player_start_position = $player_start_position
var twoplayer : bool = false
var player1
var player2

func _ready():
	Globals.player_start_position = player_start_position
	Globals.player = player
	Globals.player.follow_camera(camera)
	Globals.player.player_has_died.connect(game_over)
	control.time_is_up.connect(game_over)

func _process(_delta):
	if !twoplayer:
		camera.global_position = player.global_position
	elif twoplayer && player1 && player2:
		camera.global_position = (player1.global_position + player2.global_position) / 2
	elif player1:
		camera.global_position = player1.global_position
	elif player2:
		camera.global_position = player2.global_position
	
func reload_game():
	await get_tree().create_timer(1.0).timeout
	var new_player = player_scene.instantiate()
	add_child(new_player)
	control.reset_clock_timer()
	Globals.player = new_player
	Globals.player.player_has_died.connect(game_over)
	Globals.coins = 0
	Globals.score = 0
	Globals.player_life = 3
	Globals.respawn_player()
	
func game_over():
	get_tree().change_scene_to_file("res://scenes/game_over3.tscn")

func _on_player_3_two_players():
	twoplayer = true
	player1 = $player
	player2 = $player2
	player1.player_has_died.connect(died)
	player2.player_has_died.connect(died2)
	
func died():
	player1 = null
func died2():
	player2 = null

func _on_area_sign_body_entered(_body):
	$warning_sign/sprite.frame = 1

func _on_area_sign_body_exited(_body):
	$warning_sign/sprite.frame = 0
