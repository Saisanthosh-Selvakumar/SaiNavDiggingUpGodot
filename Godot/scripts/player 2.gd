extends CharacterBody2D

# Player.gd
# The player is invisible except for their eyes.
# WASD/Arrow keys to move, Left click or Space to shoot.

const SPEED := 280.0
const MAX_HP := 100.0
const FIRE_COOLDOWN := 0.25

var bullet_speed: int = 600.0 * Global.multiplier
var hp := MAX_HP
var fire_timer := 0.0
var look_dir := Vector2.UP
var invincible_timer := 0.0  # brief invincibility after hit
var dead := false

# Bullet scene (spawned manually)
var bullet_scene: PackedScene

func _ready():
	# Add collision shape
	var shape = CircleShape2D.new()
	shape.radius = 18.0
	$PlayerCollision.shape = shape

func _process(delta):
	if dead:
		return

	fire_timer = max(0.0, fire_timer - delta)
	invincible_timer = max(0.0, invincible_timer - delta)

	# Look toward mouse
	var mouse_pos = get_global_mouse_position()
	look_dir = (mouse_pos - global_position).normalized()
	if look_dir.length() < 0.01:
		look_dir = Vector2.UP

	# Shoot
	if (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer <= 0.0:
		_shoot()

	# Update HUD
	var hud = get_tree().get_first_node_in_group("hud")
	var hp_bar = get_node_or_null("/root/BossFight/HUD/PBox/HPBar")
	if hp_bar:
		hp_bar.value = (hp / MAX_HP) * 100.0

func _physics_process(_delta):
	if dead:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1

	velocity = dir.normalized() * SPEED
	move_and_slide()

	# Keep in screen bounds
	var vp = get_viewport_rect()
	global_position.x = clamp(global_position.x, 30, vp.size.x - 30)
	global_position.y = clamp(global_position.y, 30, vp.size.y - 30)
	
func _shoot():
	fire_timer = FIRE_COOLDOWN
	var bullet = _create_bullet()
	get_tree().root.get_node("BossFight").add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(look_dir * bullet_speed, "player_bullet")

func _create_bullet() -> Node2D:
	var b = preload("res://scripts/Bullet.gd").new()
	return b

func take_damage(amount: float):
	if invincible_timer > 0.0 or dead:
		return
	hp -= amount
	invincible_timer = 0.5
	if hp <= 0:
		_die()

func _die():
	dead = true
	visible = false
	get_node("/root/BossFight").player_died()
