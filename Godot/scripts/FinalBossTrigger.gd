extends Area2D

# FinalBossTrigger.gd
# Attach this to an Area2D in your main scene.
# When the player walks into it, the final boss spawns and the chase begins.
#
# Setup:
#   - Add a CollisionShape2D child to this Area2D to define the trigger zone
#   - Set @export vars in the inspector to point to your player node and escape area
#   - The boss will be added as a sibling of this node (child of the main scene)

@export var player_path: NodePath          # drag your Player node here in inspector
@export var escape_area_path: NodePath     # drag the EscapeZone Area2D here
@export var boss_spawn_offset := Vector2(0, -300)  # where boss appears relative to player

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)
	monitoring = true

func _on_body_entered(body):
	if triggered:
		return
	# Accept either a node path match or a node named "Player"
	var player = get_node_or_null(player_path) if player_path else null
	if player == null:
		player = get_node_or_null("/root/" + get_tree().current_scene.name + "/Player")
	if body != player and body.name != "Player":
		return

	triggered = true
	monitoring = false

#	# Spawn the boss as a sibling in the main scene
#	var boss = preload("res://scripts/FinalBoss.gd").new()
#	get_parent().add_child(boss)
#	boss.global_position = body.global_position + boss_spawn_offset
#	boss.player_node = body

	# Hook up the escape area if provided
#	var escape_area = get_node_or_null(escape_area_path)
#	if escape_area:
#		boss.escape_area = escape_area
