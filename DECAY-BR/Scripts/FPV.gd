extends Camera

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_process(true)
	pass

func _process(delta):
	if(Input.is_mouse_button_pressed(1)):
		$Weapon.test_fire()