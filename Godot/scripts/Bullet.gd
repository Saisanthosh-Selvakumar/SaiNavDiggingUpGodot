extends Node2D

# Bullet.gd
# Player's bullet - glowing orb that damages the boss.

const DAMAGE := 12.0

var velocity := Vector2.ZERO
var bullet_type := "player_bullet"
var lifetime := 0.0
var max_lifetime := 1.8
var pulse_time := 0.0

func setup(vel: Vector2, type: String):
	velocity = vel
	bullet_type = type

func _process(delta):
	lifetime += delta
	pulse_time += delta

	if lifetime > max_lifetime:
		queue_free()
		return

	global_position += velocity * delta

	# Wrap or remove if offscreen
	var vp := get_viewport_rect()
	if global_position.x < -50 or global_position.x > vp.size.x + 50 or \
	   global_position.y < -50 or global_position.y > vp.size.y + 50:
		queue_free()
		return

	# Check boss collision
	var boss := get_node_or_null("/root/BossFight/BossEye")
	if boss and not boss.dead:
		var dist := global_position.distance_to(boss.global_position)
		if dist < 90.0:
			boss.take_damage(DAMAGE)
			# Spawn hit flash
			_spawn_hit_flash()
			queue_free()
			return

	queue_redraw()

func _spawn_hit_flash():
	var flash := Node2D.new()
	var script_text = """
extends Node2D
var t := 0.0
func _process(d):
	t += d
	if t > 0.3: queue_free()
	queue_redraw()
func _draw():
	var a = 1.0 - t / 0.3
	draw_circle(Vector2.ZERO, 15.0 * (1.0 + t * 4.0), Color(0.4, 0.8, 1.0, a * 0.7))
"""
	# Can't use inline scripts easily; skip flash for now

func _draw():
	var alpha := 1.0 - (lifetime / max_lifetime) * 0.3
	var pulse := sin(pulse_time * 12.0) * 0.2 + 0.8

	# Glow
	for i in 3:
		draw_circle(Vector2.ZERO, 8.0 + i * 5.0, Color(0.3, 0.7, 1.0, alpha * 0.12))
	# Core
	draw_circle(Vector2.ZERO, 6.0 * pulse, Color(0.4, 0.8, 1.0, alpha))
	draw_circle(Vector2.ZERO, 3.0 * pulse, Color(0.9, 0.98, 1.0, alpha))
