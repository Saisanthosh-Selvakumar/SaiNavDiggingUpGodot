extends Node2D

# BossEye.gd
# A giant eye that stares at the player, shoots lasers, and has multiple attack patterns.

const MAX_HP := 500.0
const EYE_RADIUS := 90.0
const IRIS_RADIUS := 58.0
const PUPIL_RADIUS := 28.0

var hp := MAX_HP
var dead := false
var phase := 1  # 1, 2, 3

# Movement
var home_pos := Vector2(640, 260)
var current_pos := Vector2(640, 260)
var move_target := Vector2(640, 260)
var move_speed := 80.0
var move_timer := 0.0

# Attack state machine
enum AttackState { IDLE, TELEGRAPH, SWEEPLASER, BURSTLASER, MULTIEYE, ENRAGE }
var attack_state := AttackState.IDLE
var attack_timer := 0.0
var attack_phase_timer := 0.0
var current_attack := AttackState.IDLE

# Visual
var blink_timer := 0.0
var blink_duration := 0.12
var is_blinking := false
var look_at_player := true
var iris_color := Color(0.8, 0.15, 0.05)
var pupil_dir := Vector2(0, 1)
var anger_level := 0.0  # 0..1 makes eye redder and larger veins

# Laser state
var active_lasers: Array = []
var laser_angle := 0.0
var sweep_speed := 1.2
var sweep_dir := 1.0

# Spawn timer
var idle_timer := 0.0
var idle_duration := 2.5

# Screen shake
var shake_amount := 0.0

func _ready():
	home_pos = get_viewport_rect().size * Vector2(0.5, 0.28)
	current_pos = home_pos
	global_position = current_pos
	_schedule_next_move()

func _process(delta):
	if dead:
		return

	var player = get_node_or_null("/root/BossFight/Player")
	if player == null:
		return

	# Update pupil direction
	var to_player = (player.global_position - global_position).normalized()
	pupil_dir = pupil_dir.lerp(to_player, delta * 6.0)

	# Anger scales with phase
	anger_level = lerp(anger_level, float(phase - 1) / 2.0, delta * 2.0)
	iris_color = Color(0.8 + anger_level * 0.2, 0.15 - anger_level * 0.1, 0.05, 1.0)

	# Blink
	blink_timer -= delta
	if blink_timer <= 0:
		is_blinking = true
		await get_tree().create_timer(blink_duration).timeout
		is_blinking = false
		blink_timer = randf_range(3.0, 8.0) - anger_level * 2.0

	# Movement
	_update_movement(delta)

	# Attack state machine
	_update_attacks(delta, player)

	# Update HP bar
	var boss_hp_bar = get_node_or_null("/root/BossFight/HUD/BossBox/BossHP")
	if boss_hp_bar:
		boss_hp_bar.value = (hp / MAX_HP) * 100.0

	# Phase transitions
	if hp < MAX_HP * 0.66 and phase == 1:
		phase = 2
		move_speed = 120.0
		idle_duration = 1.8
		_trigger_phase_transition()
	elif hp < MAX_HP * 0.33 and phase == 2:
		phase = 3
		move_speed = 180.0
		idle_duration = 1.2
		_trigger_phase_transition()

	queue_redraw()

func _trigger_phase_transition():
	shake_amount = 1.0
	is_blinking = true
	# Spawn enrage burst
	for i in 8:
		_spawn_radial_laser(i * TAU / 8.0)

func _update_movement(delta):
	move_timer -= delta
	if move_timer <= 0:
		_schedule_next_move()

	current_pos = current_pos.move_toward(move_target, move_speed * delta)
	global_position = current_pos

func _schedule_next_move():
	move_timer = randf_range(2.0, 4.0)
	var vp = get_viewport_rect()
	move_target = Vector2(
		randf_range(EYE_RADIUS + 50, vp.size.x - EYE_RADIUS - 50),
		randf_range(EYE_RADIUS + 50, vp.size.y * 0.5)
	)

func _update_attacks(delta, player):
	attack_timer -= delta

	if attack_state == AttackState.IDLE:
		idle_timer -= delta
		if idle_timer <= 0:
			_choose_attack(player)
	elif attack_state == AttackState.SWEEPLASER:
		_update_sweep(delta, player)
	elif attack_state == AttackState.BURSTLASER:
		_update_burst(delta, player)
	elif attack_state == AttackState.MULTIEYE:
		_update_multieye(delta, player)

func _choose_attack(_player):
	var choices := [AttackState.SWEEPLASER, AttackState.BURSTLASER]
	if phase >= 2:
		choices.append(AttackState.MULTIEYE)
	current_attack = choices[randi() % choices.size()]
	attack_state = current_attack
	attack_timer = 0.0
	attack_phase_timer = 0.0

	# Determine sweep direction
	sweep_dir = 1.0 if randf() > 0.5 else -1.0

	# Starting angle points at player
	var player = get_node_or_null("/root/BossFight/Player")
	if player:
		laser_angle = (player.global_position - global_position).angle()

func _update_sweep(delta, player):
	attack_phase_timer += delta
	var sweep_time := 3.5 - float(phase - 1) * 0.5
	if attack_phase_timer < sweep_time:
		laser_angle += sweep_dir * sweep_speed * (1.0 + anger_level * 0.8) * delta
		# Fire laser
		if fmod(attack_phase_timer, 0.05) < delta:
			_spawn_laser_beam(laser_angle)
	else:
		_end_attack()

func _update_burst(delta, _player):
	attack_phase_timer += delta
	var burst_count := 3 + phase
	var interval := 0.35 - float(phase - 1) * 0.05
	if attack_timer <= 0 and attack_phase_timer < burst_count * interval:
		attack_timer = interval
		# Fire aimed shot + spread
		var player = get_node_or_null("/root/BossFight/Player")
		if player:
			var to_p = (player.global_position - global_position).angle()
			var spread := [0.0, -0.25, 0.25]
			if phase == 3:
				spread = [-0.35, -0.15, 0.0, 0.15, 0.35]
			for s in spread:
				_spawn_radial_laser(to_p + s)
	if attack_phase_timer >= burst_count * interval + 0.5:
		_end_attack()

func _update_multieye(delta, _player):
	attack_phase_timer += delta
	# Spawn rotating ring of lasers
	var ring_count := 6
	var spin_speed := 1.8
	var ring_angle := attack_phase_timer * spin_speed
	if fmod(attack_phase_timer, 0.08) < delta:
		for i in ring_count:
			_spawn_radial_laser(ring_angle + i * TAU / ring_count)
	if attack_phase_timer > 4.0:
		_end_attack()

func _end_attack():
	attack_state = AttackState.IDLE
	idle_timer = idle_duration

func _spawn_laser_beam(angle: float):
	var laser_node = Node2D.new()
	laser_node.set_script(load("res://scripts/LaserBeam.gd"))
	get_parent().add_child(laser_node)
	laser_node.setup(global_position, angle, 600.0, 0.18, Color(1.0, 0.15, 0.05, 0.9))

func _spawn_radial_laser(angle: float):
	var laser_node = Node2D.new()
	laser_node.set_script(load("res://scripts/LaserBeam.gd"))
	get_parent().add_child(laser_node)
	laser_node.setup(global_position, angle, 500.0, 0.0, Color(1.0, 0.3, 0.0, 1.0))
	
func take_damage(amount: float):
	if dead:
		return
	hp -= amount
	shake_amount = 0.3
	if hp <= 0:
		_die()

func _die():
	dead = true
	visible = false
	get_node("/root/BossFight").boss_defeated()
