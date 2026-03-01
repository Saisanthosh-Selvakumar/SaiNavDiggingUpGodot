extends Node2D

# BossFight.gd - Main scene controller

var game_over := false
var player_won := false

func _ready():
	get_tree().paused = false

func _process(_delta):
	pass

func player_died():
	game_over = true
	_show_end_screen("MARCH DIED\nmay the Commander never see\nthe light of day.\nYou are dishonorably discharged.\nBye.")

func boss_defeated():
	game_over = true
	player_won = true
	_show_end_screen("Commander March succumbs to...\nhallucinations.\nYour poor job in treating March\nWILL reflect on your record, Private.")

func _show_end_screen(text: String):
	var label = $HUD/GameOverLabel
	label.text = text
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2) if not player_won else Color(0.2, 1, 0.4))
	get_tree().paused = true
	await get_tree().create_timer(0.1).timeout
	# Unpause on input
	set_process_input(true)

func _input(event):
	if game_over and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()
