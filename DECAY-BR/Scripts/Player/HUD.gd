extends Node2D

func _ready():
	pass

func set_health_bar(health):
	get_node("healthbar/changing_bar/green_bar").margin_right = health
	get_node("healthbar/changing_bar/health_amount").set_text(str(health))

func set_ammo():
	$gun_ammo.set_text(str(Global.Inventory.get_equipped().ammo))
	$inventory_ammo.set_text(str(Global.Inventory.ammo))

func set_speed(speed):
	$speed.set_text(str(speed))