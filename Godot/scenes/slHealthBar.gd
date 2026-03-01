extends TextureProgressBar

const MAX_HEALTH: int = 100
var health: int = 100

func _ready():
	self.max_value = MAX_HEALTH
	Global.health = health
	set_bar()
	
#func _input(event: InputEvent) -> void: # replace this with actual health stuff
	#if event.is_action_pressed("ui_up"):
		#damage()
		
func damage(): # replace this once skill reduction for super moves is complete
	Global.damage(1)
	if health < 0:
		health = 110
	set_bar()
	
func set_bar():
	self.value = Global.health
