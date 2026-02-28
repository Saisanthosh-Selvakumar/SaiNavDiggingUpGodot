extends ColorRect

@export var player: Node2D

func _process(delta):
	if player == null:
		return

	var viewport_size = get_viewport_rect().size

	# CanvasLayer is screen-space, so we just need player world pos relative to camera
	var cam := get_viewport().get_camera_2d()
	var screen_pos: Vector2

	if cam != null:
		# Compute screen position relative to camera
		screen_pos = player.global_position - cam.global_position
		screen_pos += viewport_size * 0.5
	else:
		# No camera? Use world coordinates directly
		screen_pos = player.global_position

	# Update shader immediately (no lag)
	material.set_shader_parameter("light_position", screen_pos)
	material.set_shader_parameter("viewport_size", viewport_size)
