extends RigidBody

var updatable_scene_path = "res://Scenes/GunDummy.tscn"
var scene_path
var ammo
var updatable_id
var gunmodel
var gunmodel_path

var has_initialized = false

func _ready():
	pass

func get_scene_path():
	return scene_path

func get_updatable_scene_path():
	return updatable_scene_path
	
func get_ammo():
	return ammo

func set_id(updatable_id):
	self.updatable_id = updatable_id
	#print(updatable_id)

func get_id():
	return updatable_id

func set_info_set(info):
	ammo = info.ammo
	set_translation(info.translation)
	set_linear_velocity(info.linear_velocity)
	gunmodel_path = info.gunmodel_path
	if(!has_initialized):
		scene_path = info.scene_path
		add_child(load(gunmodel_path).instance())
		has_initialized = true

func get_info_set():
	var info = {}
	info.scene_path = scene_path
	info.ammo = ammo
	info.translation = get_translation()
	info.linear_velocity = get_linear_velocity()
	info.gunmodel_path = gunmodel_path
	
	info.id = updatable_id
	info.updatable_scene_path = updatable_scene_path
	return info

func delete():
	pass