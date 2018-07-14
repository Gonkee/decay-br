extends Spatial

var last_fire = 0
var threshold = 0.05
var hole
var gundummy = "res://Scenes/GunDummy.tscn"
var ads = false
var ads_fov = 30
var camera_fov = 90
var ammo = 0

# recoil
var recoil_vel = Vector2(0, 0)
var recoil_recovery = -300


# gun properties
export(int) var fire_rate
export(int) var v_recoil
export(int) var h_recoil
export(int) var mag_size
export(int) var damage
export(Vector3) var model_position
export(Vector3) var ads_model_position
export(String) var scene_path
export(String) var model_path
export(AudioStream) var sound

# nodes
var GunModel
onready var GunTween = get_node("GunTween")
onready var GunCast = get_node("GunCast")
onready var Player = get_parent().get_parent().get_parent()


func _ready():
	hole = load("res://Scenes/BulletHole.tscn")
	$GunSoundPlayer.set_stream(sound)
	add_child(load(model_path).instance())
	GunModel = get_node("GunModel")
	GunModel.set_translation(model_position)
	ammo = mag_size
	set_process(true)

func _process(delta):
	if not Player.is_network_master():
		return
	
	if(Input.is_mouse_button_pressed(1)):
		test_fire()
	var will_ads = false
	if(Input.is_mouse_button_pressed(2)):
		will_ads = true
	else:
		will_ads = false
	if(is_reloading()):
		will_ads = false
	if(!ads && will_ads):
		ads(false)
	elif(ads && !will_ads):
		ads(true)
	ads = will_ads
	if(Input.is_key_pressed(KEY_R)):
		reload()
		
	recoil(delta)

remote func ads(revert):
	GunTween.stop_all()
	var crosshair_vis
	var start_pos
	var end_pos
	var start_fov
	var end_fov
	var duration = 0.05
	if(!revert):
		crosshair_vis = false
		start_pos = model_position
		end_pos = ads_model_position
		start_fov = camera_fov
		end_fov = ads_fov
	else:
		crosshair_vis = true
		start_pos = ads_model_position
		end_pos = model_position
		start_fov = ads_fov
		end_fov = camera_fov
	GunTween.interpolate_property(GunModel, "translation", start_pos, end_pos, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	GunTween.start()
	if(Player.is_network_master()):
		Global.HUD.get_node("crosshair").set_visible(crosshair_vis)
		GunTween.interpolate_property(Player.FPV, "fov", start_fov, end_fov, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		rpc("ads", revert)

remote func fire_animation():
	var current_position = GunModel.get_translation()
	var random_gun_shift = Vector3(0, 0.01, 0).rotated(Vector3(0,0,1), rand_range(0, 6.28))
	var back_position = current_position + Vector3(0, 0, 0.2) + random_gun_shift
	GunTween.interpolate_property(GunModel, "translation", current_position, back_position, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	GunTween.interpolate_property(GunModel, "translation", back_position, current_position, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.05)
	GunTween.start()
	$GunSoundPlayer.play()
	if(Player.is_network_master()):
		rpc("fire_animation")

func test_fire():
	if(OS.get_ticks_msec() - last_fire >= 1000 / fire_rate):
			last_fire = OS.get_ticks_msec()
			fire()

func fire():
	if(ammo <= 0):
		reload()
		return
	if(GunCast.is_colliding()):
		var hit_object = GunCast.get_collider()
		if(hit_object is KinematicBody):
			Global.Player.hit_player(damage, hit_object)
		elif(hit_object is StaticBody):
			draw_hole()
	ammo -= 1
	recoil_vel = generate_recoil_vel()
	fire_animation()
	
func recoil(delta):
	if(recoil_vel.y > 0):
		recoil_vel += recoil_vel.normalized() * recoil_recovery * delta
	else:
		recoil_vel = Vector2(0, 0)
	Global.Player.safe_pitch_rotate(recoil_vel.y * delta)
	Global.Player.rotate_y(deg2rad(recoil_vel.x * delta))

func reload():
	if($ReloadTimer.is_stopped()):
		if(get_parent().ammo > 0):
			$ReloadTimer.start()
			$ReloadSoundPlayer.play()
		else:
			$ErrorSoundPlayer.play()

func generate_recoil_vel():
	return Vector2((randf() * h_recoil) - (h_recoil / 2), v_recoil)

remote func unequip():
	if Player.is_network_master():
		rpc("unequip")
	
	queue_free()
	
	if not Player.is_network_master():
		return
	
	var dropvector = Vector3(0, 0, -1.5)
	dropvector = dropvector.rotated(Vector3(0,1,0), Player.get_rotation().y)
	
	var info = {}
	info.scene_path = scene_path
	info.ammo = ammo
	info.translation = Player.get_translation() + dropvector
	info.linear_velocity = dropvector
	info.gunmodel_path = model_path
	Global.Game.add_updatable(gundummy, info)
	

func draw_hole():
	var hole_instance = hole.instance()
	Global.Game.add_child(hole_instance)
	var collision_point = GunCast.get_collision_point()
	var collision_normal = GunCast.get_collision_normal()
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

func _reload_timer_finished():
	$ReloadTimer.stop()
	var ammo_needed = mag_size - ammo
	if(get_parent().ammo >= ammo_needed):
		ammo += ammo_needed
		get_parent().ammo -= ammo_needed
	else:
		ammo += get_parent().ammo
		get_parent().ammo = 0

func is_firing():
	if(OS.get_ticks_msec() - last_fire >= 1000 / fire_rate):
		return false
	else:
		return true

func get_model():
	return GunModel

func get_scene_path():
	return scene_path

func is_ads():
	return ads

func is_reloading():
	return !$ReloadTimer.is_stopped()

func set_ammo(ammo):
	self.ammo = ammo
