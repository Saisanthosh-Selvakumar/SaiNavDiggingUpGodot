extends TextureProgressBar

const MAX_HEALTH: int = 100

func _ready():
	self.max_value = MAX_HEALTH
	set_bar()
	
func _input(event: InputEvent) -> void: # replace this with actual health stuff
	if event.is_action_pressed("jump"):
		damage()
		
func damage(): # replace this once skill reduction for super moves is complete
	#Global.damage(1)
	set_bar()
	
func set_bar():
	print(Global.health)
	self.value = Global.health
