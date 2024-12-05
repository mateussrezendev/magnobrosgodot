extends CharacterBody2D

const box_pieces = preload("res://prefabs/box_pieces2.tscn")
const life_instance = preload("res://prefabs/health_battery_rigid.tscn")

@onready var animation_player := $anim as AnimationPlayer
@onready var spawn_life := $spawn_life as Marker2D
@onready var hit_block = $hit_block as AudioStreamPlayer
@export var pieces : PackedStringArray
@export var hitpoints := 1
var impulse := 70

func break_sprite():
	for piece in pieces.size():
		var piece_instance = box_pieces.instantiate()
		get_parent().add_child(piece_instance)
		piece_instance.get_node("texture").texture = load(pieces[piece])
		piece_instance.global_position = global_position
		piece_instance.apply_impulse(Vector2(randi_range(-impulse,impulse), randi_range(-impulse, -impulse * 2)))
	queue_free()

func create_life():
	var life = life_instance.instantiate()
	get_parent().call_deferred("add_child", life)
	life.global_position = spawn_life.global_position
	life.apply_impulse(Vector2(randi_range(-50,50), -150))

func create_coin():
	pass

func create_special():
	pass
