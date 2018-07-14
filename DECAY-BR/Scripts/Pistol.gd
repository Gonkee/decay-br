extends "res://Scripts/Gun.gd"

func _ready():
	var info = {}
	info.fire_rate = 5
	info.damage = 20
	info.mag_size = 12
	info.model_position = Vector3(0.6, -0.4, -1.2)
	info.ads_model_position = Vector3(0, -0.29, -1.4)
	info.model_rotation = Vector3(90, 90, 0)
	info.v_recoil = 40
	info.h_recoil = 40
	info.scene_path = "res://Scenes/Pistol.tscn"
	info.model_path = "res://Models/pistol.obj"
	info.sound_path = "res://Sounds/silenced gun.ogg"
	self.init(info)