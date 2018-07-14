extends "res://Scripts/Weapons/Gun.gd"

export(int) var pellet_spread_degrees

func _ready():
	var one_rotation = 360 / 8
	var i = 1
	while(i <= 8):
		var ray = get_node("RayCasts").get_node(str("RC", i))
		ray.rotate_x(deg2rad(pellet_spread_degrees))
		ray.rotate_z(deg2rad(one_rotation * i))
		i += 1

func fire():
	if(ammo <= 0):
		reload()
		return
	var i = 1
	while(i <= 9):
		var ray = get_node("RayCasts").get_node(str("RC", i))
		if(ray.is_colliding()):
			var hit_object = ray.get_collider()
			if(hit_object is KinematicBody):
				Global.Player.hit_player(damage, hit_object)
			elif(hit_object is StaticBody):
				draw_hole(ray)
		i += 1
	ammo -= 1
	recoil_vel = generate_recoil_vel()
	fire_animation()
	
func draw_hole(ray):
	var hole_instance = hole.instance()
	Global.Game.add_child(hole_instance)
	var collision_point = ray.get_collision_point()
	var collision_normal = ray.get_collision_normal()
	hole_instance.translation = collision_point
#		hole_instance.look_at(collision_point + collision_normal, Vector3(0, 1, 0))
#		print(collision_point + collision_normal)

	if(Vector2(collision_normal.x, collision_normal.y).length() > threshold):
		var up_vector = Vector2(0, 1)
		var z_rotation = rad2deg(acos(up_vector.dot(Vector2(collision_normal.x, collision_normal.y).normalized())))
		# dot product is absolute, doesn't have negative degrees
		if(collision_normal.x > threshold):
			z_rotation = -z_rotation
		hole_instance.rotate_object_local(Vector3(0, 0, 1), deg2rad(z_rotation))

	if(Vector2(collision_normal.z, collision_normal.y).length() > threshold):
		var up_vector = Vector2(0, 1)
		var x_rotation = rad2deg(acos(up_vector.dot(Vector2(collision_normal.z, collision_normal.y).normalized())))
		# dot product is absolute, doesn't have negative degrees
		if(collision_normal.z < -threshold):
			x_rotation = -x_rotation
		hole_instance.rotate_object_local(Vector3(1, 0, 0), deg2rad(x_rotation))
