extends Node2D

# LaserBeam.gd
# A laser that travels from origin in a direction, damages player on contact.

const LASER_LENGTH := 1200.0
const DAMAGE := 15.0
const PULSE_SPEED := 8.0

var direction := Vector2.RIGHT
var speed := 500.0
var lifetime := 0.0
var max_lifetime := 0.4
var beam_color := Color(1.0, 0.15, 0.05, 0.9)
var origin := Vector2.ZERO
var traveled := 0.0
var hit_player := false
var is_radial := false  # if true, travels like a projectile from origin outward
var pulse_time := 0.0
var width := 5.0
var fade_alpha := 1.0

func setup(from: Vector2, angle: float, spd: float, life: float, color: Color):
	origin = from
	global_position = from
	direction = Vector2(cos(angle), sin(angle))
	speed = spd
	beam_color = color
	if life <= 0.0:
		is_radial = true
		max_lifetime = LASER_LENGTH / spd + 0.1
	else:
		max_lifetime = life

func _process(delta):
	lifetime += delta
	pulse_time += delta

	if lifetime >= max_lifetime:
		queue_free()
		return

	fade_alpha = 1.0 - (lifetime / max_lifetime)

	if is_radial:
		traveled += speed * delta
		global_position = origin + direction * traveled
	else:
		# Beam style — stays at origin but grows
		pass

	# Check player collision
	var player = get_node_or_null("/root/BossFight/Player")
	if player and not hit_player and not player.dead:
		var dist: float
		if is_radial:
			dist = global_position.distance_to(player.global_position)
			if dist < 20.0:
				hit_player = true
				player.take_damage(DAMAGE)
		else:
			# Line collision check
			var beam_end := origin + direction * LASER_LENGTH
			dist = _point_to_segment_dist(player.global_position, origin, beam_end)
			if dist < 18.0:
				player.take_damage(DAMAGE * delta * 60.0)  # continuous

	queue_redraw()

func _draw():
	var alpha := fade_alpha * beam_color.a
	var pulse := (sin(pulse_time * PULSE_SPEED) * 0.3 + 0.7)

	if is_radial:
		# Draw as a traveling orb
		var orb_r := 7.0 * pulse
		# Glow layers
		for i in 3:
			var gr := orb_r + i * 8.0
			draw_circle(Vector2.ZERO, gr, Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.15))
		draw_circle(Vector2.ZERO, orb_r, Color(beam_color.r, beam_color.g, beam_color.b, alpha))
		draw_circle(Vector2.ZERO, orb_r * 0.4, Color(1, 0.9, 0.8, alpha))
		# Trail
		for i in 5:
			var trail_pos := -direction * float(i + 1) * 10.0
			draw_circle(trail_pos, orb_r * (1.0 - float(i + 1) * 0.18), Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.3 * (1.0 - float(i) * 0.2)))
	else:
		# Draw as a beam from origin
		# Relative to self which is at origin
		var local_end := direction * LASER_LENGTH
		var beam_w := (4.0 + pulse * 3.0)

		# Glow layers
		for i in 3:
			var gw := beam_w + i * 7.0
			var ga := alpha * 0.12
			draw_line(Vector2.ZERO, local_end, Color(beam_color.r, beam_color.g, beam_color.b, ga), gw)

		# Core beam
		draw_line(Vector2.ZERO, local_end, Color(beam_color.r, beam_color.g, beam_color.b, alpha * 0.85), beam_w)
		# Bright center
		draw_line(Vector2.ZERO, local_end, Color(1, 0.85, 0.7, alpha * 0.7), beam_w * 0.3)

func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := (p - a).dot(ab) / ab.length_squared()
	t = clamp(t, 0.0, 1.0)
	return (p - (a + ab * t)).length()
