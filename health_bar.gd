extends Control

@onready var e_r_i_c_k = $"../../enemies/E_R_I_C_K"
@onready var bar = $"TextureProgressBar"

func _process(_delta):
	if is_instance_valid(e_r_i_c_k):
		bar.value = e_r_i_c_k.health_points
	else:
		visible = false
