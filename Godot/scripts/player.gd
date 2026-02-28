extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -200.0

func _physics_process(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func on_vignettearea_body_entered(body: Node2D) -> void:
	if body == self:
		ColorRect.visible = true
		print("Vignette visible")
		ColorRect.modulate.a = 0.0
		create_tween().tween_property(ColorRect, "modulate:a", 10, 0.5)
