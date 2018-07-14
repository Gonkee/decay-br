extends "res://Scripts/Player/PlayerBasic.gd"

# variables
var run_speed = 12
var walk_speed = 8
var speed = 0
var mouse_sensitivity = 0.15
var gravity = -9.8 * 6
var gravity_max = -150
var jump_force = 17
var air_speed = 0.75
var in_air_slowdown = 0.2
var friction = 4
var camera_fov = 90

var ground_accel = 20
var air_accel = 7.5

# changing variables
var health = 100
var alive = true
var sprinting = false
var raycast_contact = false
var horizontal_vel = Vector2(0, 0)
var mouse_movement = Vector2(0, 0)
var y_vel = 0

# nodes
onready var Head = get_node("Head")
onready var FPV = get_node("Head/FPV")
onready var HUD = get_node("Head/FPV/HUD")
onready var PickupCast = get_node("Head/FPV/PickupCast")
onready var GroundCast = get_node("GroundCast")
onready var Model = get_node("PlayerModel")
onready var Game = Global.Game

func _ready():
	#set_translation(get_node("/root/Game/World/SpawnPoint").get_translation())
	pass

func update(delta):
	input(delta)
	rotateplayer(delta)
	moveplayer(delta)
	HUD.set_health_bar(health)
	HUD.set_ammo()
	HUD.set_speed(horizontal_vel.length())
	
func _input(event):
	if(event is InputEventMouseMotion):
		mouse_movement = event.relative

func reset():
	alive = true
	health = 100
	FPV.get_node("DieNotification").set_visible(false)
	set_translation(Global.SpawnPoint.get_translation())
	horizontal_vel = Vector2(0, 0)
	y_vel = 0

func hit_player(damage, target_player):
	print(str(my_id), " hit player ", str(target_player.get_id()))
	target_player.take_damage(damage, my_id)

remote func take_damage(damage, from_who):
	print(str(my_id), " hit by ", str(from_who))
	health -= damage
	if(health <= 0 && alive):
		die()

func moveplayer(delta):
	# add gravity to y velocity
	y_vel += gravity * delta
	if (y_vel < gravity_max):
		y_vel = gravity_max
	# space = jump
	if(Input.is_key_pressed(KEY_SPACE) && is_on_floor()):
		y_vel = jump_force
		raycast_contact = false
	#create 3D movement vector
	velocity = Vector3(horizontal_vel.x, y_vel, horizontal_vel.y)
	# move and slide
	move_and_slide(velocity, Vector3(0, 1, 0), 0.05, 4, deg2rad(45))
	# if on floor, y velocity = 0
	if(is_on_floor()):
		raycast_contact = true
		y_vel = 0
	elif(!GroundCast.is_colliding()):
		raycast_contact = false
	
	if(raycast_contact && !is_on_floor()):
		move_and_collide(Vector3(0, -1, 0))
	# prevent sliding upwards when jumping
	if(get_slide_count() > 0):
		var collision = get_slide_collision(0)
		var remainder_vel = collision.remainder
		var horizontal_vel_change = Vector2(remainder_vel.x, remainder_vel.z) * friction
		var y_vel_change = remainder_vel.y * friction
#		if(horizontal_vel.length() > horizontal_vel_change.length()):
#			horizontal_vel -= horizontal_vel_change
#		else:
#			horizontal_vel = Vector2(0, 0)
		if(abs(y_vel) > abs(y_vel_change)):
			y_vel -= y_vel_change
		else:
			y_vel = 0
			
func rotateplayer(delta):
	if(mouse_movement.length() > 0):
		# pitch = up & down
		# yaw = left & right
		var pitch = -(mouse_movement.y) * (mouse_sensitivity * FPV.get_fov() / camera_fov)
		var yaw = -(mouse_movement.x) * (mouse_sensitivity * FPV.get_fov() / camera_fov)
		
		safe_pitch_rotate(pitch)
		rotate_y(deg2rad(yaw))
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_movement = Vector2(0, 0)
	
func input(delta):
	if(Input.is_action_just_pressed("equip_item")):
		if(PickupCast.get_collider() != null):
			if(PickupCast.get_collider() is RigidBody):
				Inventory.equip(PickupCast.get_collider())
	if(Input.is_key_pressed(KEY_ENTER) && !alive):
		print("reset")
		Global.Game.reset_all()
	if(Input.is_key_pressed(KEY_SHIFT)):
		sprinting = true
	else:
		sprinting = false
	if(Inventory.get_equipped().is_firing()):
		sprinting = false
	if(Inventory.get_equipped().is_ads()):
		sprinting = false
	if(Inventory.get_equipped().is_reloading()):
		sprinting = false
	movement_input(delta)

func movement_input(delta):
	var speed
	if(sprinting):
		speed = run_speed
	else:
		speed = walk_speed
	var accel
	if(is_on_floor()):
		accel = ground_accel
	else:
		accel = air_accel
		speed *= air_speed
		
	var target = Vector2(0, 0)
	if(Input.is_key_pressed(KEY_W)):
		target.y = -1
	elif(Input.is_key_pressed(KEY_S)):
		target.y = 1
	if(Input.is_key_pressed(KEY_A)):
		target.x = -1
	elif(Input.is_key_pressed(KEY_D)):
		target.x = 1
	target = target.normalized() * speed
	target = target.rotated(-rotation.y)
	var vel_change = (target - horizontal_vel) * accel
	#print((target - horizontal_vel).length())
	#horizontal_vel += vel_change * delta
	horizontal_vel = horizontal_vel.linear_interpolate(target, accel * delta)

func safe_pitch_rotate(degrees):
	if(rad2deg(Head.get_rotation().x) + degrees > 89):
		Head.rotation.x = deg2rad(89)
	elif(rad2deg(Head.get_rotation().x) + degrees <= -89):
		Head.rotation.x = -deg2rad(89)
	else:
		Head.rotate_object_local(Vector3(1,0,0), deg2rad(degrees))