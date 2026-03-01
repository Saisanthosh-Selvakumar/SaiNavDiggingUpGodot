extends Area2D

# EscapeZone.gd
# Attach to an Area2D with a CollisionShape2D child.
# The FinalBoss watches this area — when the player enters, they win.
#
# This node also draws a visible "exit" marker so the player can see
# where they're running to. Remove _draw() if you have your own visuals.

var pulse_time := 0.0
var activated  := false   # lights up once the boss spawns

func _ready():
	# Boss will connect body_entered via FinalBossTrigger.
	# This script just handles the visual.
	pass

func activate():
	activated = true

func _process(delta):
	pulse_time += delta
	queue_redraw()

func _draw():
	if not activated:
		return

	var pulse := sin(pulse_time * 4.0) * 0.3 + 0.7
	var r     := 50.0  # match your CollisionShape2D radius

	# Outer ring glow
	for i in 3:
		draw_arc(Vector2.ZERO, r + i * 10.0, 0, TAU, 48,
			Color(0.3, 1.0, 0.5, 0.08 * pulse), 2.0)

	# Main ring
	draw_arc(Vector2.ZERO, r, 0, TAU, 64,
		Color(0.4, 1.0, 0.55, 0.85 * pulse), 3.0)

	# Inner fill
	draw_circle(Vector2.ZERO, r * 0.85,
		Color(0.3, 1.0, 0.45, 0.12 * pulse))

	# Arrow pointing up — "surface is this way"
	var arrow_color := Color(0.5, 1.0, 0.6, 0.9 * pulse)
	draw_line(Vector2(0, 15),  Vector2(0, -15),  arrow_color, 3.0)
	draw_line(Vector2(0, -15), Vector2(-10, -5), arrow_color, 3.0)
	draw_line(Vector2(0, -15), Vector2( 10, -5), arrow_color, 3.0)
