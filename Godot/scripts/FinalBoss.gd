extends CharacterBody2D

# FinalBoss.gd
# The final boss. Spawns in the main scene, chases the player,
# and fires projectiles. The player wins by reaching the escape zone.
#
# This boss represents the fear of losing everything —
# it looks like a crumbling silhouette of a home, drifting apart
# as it takes damage, until there's nothing left.
#
# No sprites required — drawn entirely in code.
# Swap _draw() for Sprite2D logic if you have your own art.

# ── References (set by FinalBossTrigger) ─────────────────────────────────────
var player_node: Node = null
var escape_area: Node = null  # Area2D — player wins by entering this

# ── Stats ─────────────────────────────────────────────────────────────────────
const MAX_HP            := 300.0
const CHASE_SPEED_BASE  := 90.0
const SHOOT_INTERVAL    := 1.6   # seconds between shots
const PROJECTILE_SPEED  := 260.0
const CONTACT_DAMAGE    := 20.0
const CONTACT_COOLDOWN  := 1.0   # seconds between contact hits
const COLLISION_RADIUS  := 48.0

var hp               := MAX_HP
var dead             := false
var contact_timer    := 0.0
var shoot_timer      := 0.0
var phase            := 1        # 1 = chase, 2 = frantic, 3 = desperate
var aggro_timer      := 0.0      # how long since player was last seen
var chase_speed      := CHASE_SPEED_BASE

# ── Visual state ──────────────────────────────────────────────────────────────
var fragment_offsets: Array[Vector2] = []  # house fragments drift apart on damage
var fragment_angles:  Array[float]   = []
var fragment_drifts:  Array[Vector2] = []
var damage_flash     := 0.0
var pulse_time       := 0.0
var enter_time       := 0.0       # seconds since spawn, for entrance animation

# ── Escape tracking ───────────────────────────────────────────────────────────
var escape_connected := false

func _ready():
	# Collision shape
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = COLLISION_RADIUS
	col.shape = shape
	add_child(col)

	# Initialise house fragments — 8 rough rectangular pieces
	for i in 8:
		fragment_offsets.append(Vector2.ZERO)
		fragment_angles.append(0.0)
		var drift_angle := i * TAU / 8.0 + randf() * 0.4
		fragment_drifts.append(Vector2(cos(drift_angle), sin(drift_angle)))

	# Connect escape area if already assigned
	_try_connect_escape()

	# Entrance: boss fades/grows in over 1 second
	enter_time = 0.0

func _try_connect_escape():
	if escape_area and not escape_connected:
		escape_area.body_entered.connect(_on_escape_body_entered)
		escape_connected = true

func _process(delta):
	if dead:
		return

	enter_time  += delta
	pulse_time  += delta
	damage_flash = max(0.0, damage_flash - delta * 3.0)
	contact_timer = max(0.0, contact_timer - delta)
	shoot_timer   = max(0.0, shoot_timer - delta)

	# Late-connect escape area (in case it wasn't ready at _ready time)
	_try_connect_escape()

	# Phase transitions
	var hp_frac := hp / MAX_HP
	if   hp_frac < 0.33 and phase < 3:
		phase = 3
		chase_speed = CHASE_SPEED_BASE * 1.6
	elif hp_frac < 0.66 and phase < 2:
		phase = 2
		chase_speed = CHASE_SPEED_BASE * 1.25

	if player_node == null or not is_instance_valid(player_node):
		return

	_update_ai(delta)
	queue_redraw()

func _physics_process(delta):
	if dead or player_node == null or not is_instance_valid(player_node):
		return
	if enter_time < 0.6:
		return  # frozen during entrance

	# Chase the player
	var to_player := (player_node.global_position - global_position)
	var dist      := to_player.length()

	if dist > 10.0:
		velocity = to_player.normalized() * chase_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Contact damage
	if dist < COLLISION_RADIUS + 20.0 and contact_timer <= 0.0:
		if player_node.has_method("take_damage"):
			player_node.take_damage(CONTACT_DAMAGE)
			contact_timer = CONTACT_COOLDOWN

func _update_ai(delta):
	if shoot_timer <= 0.0:
		_shoot()
		# Phase 2+: fire an extra spread shot
		if phase >= 2:
			await get_tree().create_timer(0.25).timeout
			if not dead:
				_shoot_spread()
		# Phase 3: fire a third aimed burst
		if phase >= 3:
			await get_tree().create_timer(0.45).timeout
			if not dead:
				_shoot()
		shoot_timer = SHOOT_INTERVAL - float(phase - 1) * 0.3

func _shoot():
	if player_node == null or not is_instance_valid(player_node):
		return
	var dir := (player_node.global_position - global_position).normalized()
	_spawn_projectile(dir)

func _shoot_spread():
	if player_node == null or not is_instance_valid(player_node):
		return
	var dir := (player_node.global_position - global_position).normalized()
	var spread_angles := [-0.3, 0.0, 0.3]
	for a in spread_angles:
		_spawn_projectile(dir.rotated(a))

func _spawn_projectile(dir: Vector2):
	var proj = _FinalBossProjectile.new()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.setup(dir * PROJECTILE_SPEED, player_node)

# ── Taking damage ─────────────────────────────────────────────────────────────
func take_damage(amount: float):
	if dead:
		return
	hp -= amount
	damage_flash = 1.0

	# Fragments drift further apart with each hit
	var drift_scale := 1.0 - (hp / MAX_HP)
	for i in fragment_offsets.size():
		fragment_offsets[i] = fragment_drifts[i] * drift_scale * 60.0
		fragment_angles[i]  = drift_scale * (i % 2 == 0? 0.3 : -0.3)

	if hp <= 0.0:
		_die()

func _die():
	dead = true
	# Play crumble — fragments fly off
	var tween := create_tween()
	for i in fragment_offsets.size():
		var target := fragment_drifts[i] * 400.0
		tween.parallel().tween_property(self, "fragment_offsets[%d]" % i,
			target, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
	# Notify scene
	var scene_root := get_tree().current_scene
	if scene_root.has_method("final_boss_defeated"):
		scene_root.final_boss_defeated()

# ── Drawing ───────────────────────────────────────────────────────────────────
func _draw():
	var enter_scale := min(1.0, enter_time / 0.6)  # grows in over 0.6s
	var hp_frac     := clamp(hp / MAX_HP, 0.0, 1.0)

	# Pulse glow — gets angrier (redder, larger) at low HP
	var glow_color := Color(
		0.6 + (1.0 - hp_frac) * 0.4,
		0.4 * hp_frac,
		0.4 * hp_frac,
		0.18
	)
	for i in 3:
		draw_circle(Vector2.ZERO, (70.0 + i * 20.0) * enter_scale,
			Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a - i * 0.04))

	# Flash white on damage
	if damage_flash > 0.0:
		draw_circle(Vector2.ZERO, 65.0 * enter_scale,
			Color(1, 1, 1, damage_flash * 0.4))

	# Draw the house silhouette as fragments
	_draw_house(enter_scale, hp_frac)

func _draw_house(scale: float, hp_frac: float):
	# The "house" is made of 8 simple rectangles representing
	# walls, roof, windows, door — each one a fragment that drifts apart.
	var darkness := 1.0 - hp_frac  # how broken it looks
	var base_color := Color(
		0.15 + darkness * 0.5,
		0.12 - darkness * 0.05,
		0.10 - darkness * 0.05,
		0.9 * scale
	)

	# Fragment definitions: [rect center offset, size, rotation_scale]
	var fragments: Array = [
		# Walls
		[Vector2(-20, 10),  Vector2(35, 55), 0],
		[Vector2( 20, 10),  Vector2(35, 55), 0],
		# Roof left & right slopes
		[Vector2(-22, -30), Vector2(30, 18), 1],
		[Vector2( 22, -30), Vector2(30, 18), -1],
		# Roof peak
		[Vector2(0, -44),   Vector2(20, 14), 0],
		# Windows
		[Vector2(-20, 0),   Vector2(12, 12), 1],
		[Vector2( 20, 0),   Vector2(12, 12), -1],
		# Door
		[Vector2(0, 22),    Vector2(14, 22), 0],
	]

	for i in fragments.size():
		var frag      = fragments[i]
		var center    : Vector2 = frag[0] * scale
		var size      : Vector2 = frag[1] * scale
		var rot_sign  : int     = frag[2]

		var offset    := fragment_offsets[i] * scale
		var angle     := fragment_angles[i] * rot_sign

		var rect := Rect2(center + offset - size * 0.5, size)

		# Draw with rotation by using draw_set_transform
		draw_set_transform(center + offset, angle, Vector2.ONE)
		var local_rect := Rect2(-size * 0.5, size)

		# Fragment color — windows glow faintly
		var frag_color := base_color
		if i == 5 or i == 6:  # windows
			frag_color = Color(
				0.8 - darkness * 0.6,
				0.7 - darkness * 0.5,
				0.3 - darkness * 0.2,
				0.85 * scale
			)

		draw_rect(local_rect, frag_color)

		# Outline
		draw_rect(local_rect, Color(0.05, 0.0, 0.0, 0.5 * scale), false, 1.5)

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # reset transform

	# Pulsing "core" — the fear itself, visible through the cracks at low HP
	if hp_frac < 0.5:
		var core_alpha := (0.5 - hp_frac) * 2.0 * (sin(pulse_time * 6.0) * 0.3 + 0.7)
		draw_circle(Vector2.ZERO, 18.0 * scale, Color(1.0, 0.3, 0.1, core_alpha * scale))

# ── Escape handler ────────────────────────────────────────────────────────────
func _on_escape_body_entered(body):
	if body == player_node or body.name == "Player":
		_player_escaped()

func _player_escaped():
	dead = true
	# Scene should handle the win — call a method if it exists
	var scene_root := get_tree().current_scene
	if scene_root.has_method("player_escaped"):
		scene_root.player_escaped()
	queue_free()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Inner class: the boss's projectile
# Kept in the same file so you only need one script.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _FinalBossProjectile extends Node2D:
	const DAMAGE      := 18.0
	const MAX_LIFE    := 3.5

	var vel           := Vector2.ZERO
	var player        : Node = null
	var lifetime      := 0.0
	var pulse_time    := 0.0
	var hit           := false

	func setup(velocity: Vector2, player_ref: Node):
		vel    = velocity
		player = player_ref

	func _process(delta):
		lifetime   += delta
		pulse_time += delta

		if lifetime > MAX_LIFE:
			queue_free()
			return

		global_position += vel * delta

		# Off-screen cull
		var vp := get_viewport_rect()
		if global_position.x < -80 or global_position.x > vp.size.x + 80 or \
		   global_position.y < -80 or global_position.y > vp.size.y + 80:
			queue_free()
			return

		# Damage player on contact
		if not hit and player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) < 22.0:
				hit = true
				if player.has_method("take_damage"):
					player.take_damage(DAMAGE)
				queue_free()
				return

		queue_redraw()

	func _draw():
		var life_frac := lifetime / MAX_LIFE
		var alpha     := 1.0 - life_frac * 0.5
		var pulse     := sin(pulse_time * 10.0) * 0.25 + 0.75

		# Outer glow
		for i in 3:
			draw_circle(Vector2.ZERO, 14.0 + i * 7.0,
				Color(0.8, 0.25, 0.05, alpha * 0.10))
		# Core orb
		draw_circle(Vector2.ZERO, 9.0 * pulse, Color(0.85, 0.3, 0.05, alpha))
		# Bright center
		draw_circle(Vector2.ZERO, 4.5 * pulse, Color(1.0, 0.8, 0.5, alpha))
		# Trail
		var trail_dir := -vel.normalized()
		for i in 4:
			var tp := trail_dir * float(i + 1) * 9.0
			draw_circle(tp, (7.0 - i * 1.5) * pulse,
				Color(0.8, 0.2, 0.05, alpha * 0.25 * (1.0 - float(i) * 0.22)))
