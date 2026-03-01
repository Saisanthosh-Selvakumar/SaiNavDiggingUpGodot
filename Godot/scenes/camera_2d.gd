extends Camera2D

# 1. Look at your Player node's name. If it's exactly "Player", this works.
# If not, drag your player node into this slot in the Inspector.
@export var player: CharacterBody2D 
@export var idle_zoom: float = 3.5  # Normal zoom
@export var fast_zoom: float = 3.2 # Only zooms out a tiny bit (Change to 0.9 if you want more)

func _ready():
	# If you forgot to assign the player in the Inspector, 
	# this tries to find it automatically in the parent.
	if not player:
		player = get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	if not player: 
		return

	# --- FIX 1: THE LOOK AHEAD ---
	var target_x = 0.0
	# Check if moving right or left
	if player.velocity.x > 10:
		target_x = 100.0 # Adjust this number for how far it looks right
	elif player.velocity.x < -10:
		target_x = -100.0 # Adjust this number for how far it looks left
	
	# Smoothly slide the offset.x to the target
	offset.x = lerp(offset.x, target_x, 2.0 * delta)

	# --- FIX 2: THE ZOOM ---
	# Get speed as a value between 0 and 1
	#var speed_factor = clamp(abs(player.velocity.x) / 350.0, 0.0, 1.0)
	
	# Zoom out (0.8) when fast, Zoom in (1.0) when slow
	#var z = lerp(1.0, 1.0, speed_factor)
	#zoom = zoom.lerp(Vector2(z, z), 2.0 * delta)
	
		# --- THE ZOOM (REFINED) ---
	var speed_factor = clamp(abs(player.velocity.x) / 350.0, 0.0, 1.0)
	
	# Use our new variables here
	var z = lerp(idle_zoom, fast_zoom, speed_factor)
	zoom = zoom.lerp(Vector2(z, z), 2.0 * delta)
