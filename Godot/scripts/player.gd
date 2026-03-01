extends CharacterBody2D

# --- Constants ---
const SPEED = 200.0 
const ACCELERATION = 1200.0 
const FRICTION = 1000.0 
const JUMP_VELOCITY = -300.0 
const FALL_THRESHOLD = 250

# Gravity Variants
const GRAVITY = 600.0 
const FALL_GRAVITY = 800.0 
const FAST_FALL_GRAVITY = 1000.0 

# Juice & Feel
const INPUT_BUFFER_PATIENCE = 0.1 
const COYOTE_TIME = 0.08

# --- Variables ---
var input_buffer: Timer 
var coyote_timer: Timer 
var coyote_jump_available := true
var last_y_velocity = 0.0

func _ready() -> void:
	# 1. Set up Input Buffer (allows pressing jump slightly before hitting ground)
	input_buffer = Timer.new()
	input_buffer.wait_time = INPUT_BUFFER_PATIENCE
	input_buffer.one_shot = true
	add_child(input_buffer)

	# 2. Set up Coyote Timer (allows jumping slightly after leaving a ledge)
	coyote_timer = Timer.new()
	coyote_timer.wait_time = COYOTE_TIME
	coyote_timer.one_shot = true
	add_child(coyote_timer)
	
	# Using a Lambda to reset jump availability when timer runs out
	coyote_timer.timeout.connect(func(): coyote_jump_available = false)

func _physics_process(delta: float) -> void:
	# --- 1. Inputs ---
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var jump_attempted := Input.is_action_just_pressed("jump")
	var jump_released := Input.is_action_just_released("jump")

	# --- 2. Jump Logic ---
	if jump_attempted:
		input_buffer.start()

	# Execute jump if buffer is active and we are "on the ground" (via coyote)
	if input_buffer.time_left > 0 and coyote_jump_available:
		velocity.y = JUMP_VELOCITY
		coyote_jump_available = false
		input_buffer.stop()

	# Variable Jump Height: If player lets go early, cut the upward momentum
	if jump_released and velocity.y < 0:
		velocity.y = max(velocity.y, JUMP_VELOCITY / 4)

	# --- 3. Gravity & State Management ---
	if is_on_floor():
		coyote_jump_available = true
		coyote_timer.stop()
	else:
		# Start coyote timer the moment we fall off a ledge
		if coyote_jump_available and coyote_timer.is_stopped():
			coyote_timer.start()
		
		# Apply our custom gravity magnitude
		velocity.y += get_gravity_magnitude() * delta

	# --- 4. Horizontal Movement ---
	var dash_multiplier := 2.0 if Input.is_action_pressed("dash") else 1.0
	var target_speed = horizontal_input * SPEED * dash_multiplier
	
	if horizontal_input:
		# Accelerate toward max speed
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		# Friction brings us to a stop
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	last_y_velocity = velocity.y
	
	# --- 5. Apply Movement ---
	move_and_slide()
	
	if is_on_floor() and last_y_velocity > FALL_THRESHOLD:
		var impact = pow(abs(last_y_velocity), (1/25))
		Global.damage(impact)

## Renamed from get_gravity() to avoid conflict with Godot 4.3+ built-in function
func get_gravity_magnitude() -> float:
	if Input.is_action_pressed("fast_fall"):
		return FAST_FALL_GRAVITY
	
	# Return higher gravity when falling for a "snappier" feel
	return GRAVITY if velocity.y < 0 else FALL_GRAVITY
