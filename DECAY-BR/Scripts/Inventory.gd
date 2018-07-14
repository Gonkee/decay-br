extends Spatial

var ammo = 100
var pistol = load("res://Scenes/Weapons/Pistol.tscn")
var shotgun = load("res://Scenes/Weapons/Shotgun.tscn")
var current_equipped
var shotgun_bool = false
var equipped_id = 0

func _ready():
	current_equipped = pistol.instance()
	current_equipped.set_name(str(equipped_id))
	add_child(current_equipped)
	set_process(true)

func _process(delta):
	if not get_parent().get_parent().is_network_master():
		return
	
	if(Input.is_key_pressed(KEY_J) && !shotgun_bool):
		shotgun_bool = true
		current_equipped.unequip()
		current_equipped = shotgun.instance()
		equipped_id += 1
		current_equipped.set_name(str(equipped_id))
		add_child(current_equipped)

func equip(gundummy_node):
	current_equipped.unequip()
	current_equipped = load(gundummy_node.get_scene_path()).instance()
	equipped_id += 1
	current_equipped.set_name(str(equipped_id))
	add_child(current_equipped)
	current_equipped.set_ammo(gundummy_node.get_ammo())
	Global.Game.delete_updatable(gundummy_node.get_id(), true)

# using a consistant name system to ensure rpc() calls the right node on the other peers
func set_equipped_name(id):
	if weakref(current_equipped).get_ref():
		if current_equipped.get_name() != str(id):
			current_equipped.set_name(str(id))
	
func set_equipped(scene_path):
	if weakref(current_equipped).get_ref():
		if current_equipped.get_scene_path() == scene_path:
			return
		current_equipped.queue_free()
	current_equipped = load(scene_path).instance()
	add_child(current_equipped)

func get_equipped():
	return current_equipped
