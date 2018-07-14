extends KinematicBody

onready var Inventory = get_node("Head/Inventory")
onready var dissolve_material = load("res://Shaders/Dissolve Shader/dissolve_material.tres")

var velocity = Vector3(0, 0, 0)
var my_id

func _ready():
	set_process(true)

func init(my_id):
	self.my_id = my_id
	set_network_master(my_id)

func _process(delta):
	update(delta)

func update(delta):
	move_and_slide(velocity)

remote func take_damage(damage, from_who):
	if(!is_network_master()):
		rpc_id(my_id, "take_damage", damage, from_who)

func network_tick():
	rpc_unreliable("set_info_set", get_info_set())

remote func reload():
	# play reload animation/sound
	if(is_network_master()):
		rpc("reload")


remote func equip():
	# change gun model
	if(is_network_master()):
		rpc("equip")

func get_id():
	return my_id

# currently the dissolve animation does nothing as the player is deleted immediately
# a separate object must be created to actually show the dissolve animation
remote func die():
	dissolve_material.set_shader_param("start_time", float(OS.get_ticks_msec()) / 1000)
	dissolve_material.set_shader_param("dissolve_duration", 1.0)
	dissolve_material.set_shader_param("edge_highlight", 0.02)
	dissolve_material.set_shader_param("albedo", Vector3(0.2, 0.2, 1.0))
	get_node("PlayerModel").set_surface_material(0, dissolve_material)
	Inventory.get_equipped().get_model().set_surface_material(0, dissolve_material)
	if(is_network_master()):
		Global.Game.delete_player(Global.Game.my_id)
		rpc("die")

func get_info_set():
	var info = {}
	info.translation = get_translation()
	info.rotation = get_rotation()
	info.velocity = velocity
	info.equipped = Inventory.get_equipped().get_scene_path()
	info.equipped_id = Inventory.equipped_id
	info.equipped_transform = Inventory.get_equipped().get_model().get_global_transform()
	return info

remote func set_info_set(info):
	set_translation(info.translation)
	set_rotation(info.rotation)
	velocity = info.velocity
	Inventory.set_equipped(info.equipped)
	Inventory.set_equipped_name(info.equipped_id)
	Inventory.get_equipped().get_model().set_global_transform(info.equipped_transform)