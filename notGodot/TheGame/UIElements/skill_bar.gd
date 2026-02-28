extends ProgressBar

const MAX_SKILL: int = 100
var skill: int = 10

func _ready():
	self.max_value = MAX_SKILL
	set_health_bar()
	
func _input(event: InputEvent) -> void: # replace this with actual health stuff
	if event.is_action_pressed("ui_up"):
		damage()
		
func damage(): # replace this once skill reduction for super moves is complete
	skill += 1
	if skill > MAX_SKILL:	
		skill = 0
	set_health_bar()

func set_health_bar():
	self.value = skill
