extends Control

@export var screen_wipe_timer:Timer
@export var quit_fade_timer:Timer
@export var screen_wipe:Gradient
@export var screen_wipe_node:Node
@export var music_node:Node


func _ready():
	get_node("../ScreenWipe").show()


func _process(delta):
	# Pause
	if Input.is_action_just_pressed("Pause"):
		pause()
	
	# Quit fade, load in fade
	if !quit_fade_timer.is_stopped():
		screen_wipe_node.modulate = screen_wipe.sample(
				1 - (quit_fade_timer.time_left / quit_fade_timer.wait_time))
	elif !screen_wipe_timer.is_stopped():
		screen_wipe_node.modulate = screen_wipe.sample(
				screen_wipe_timer.time_left / screen_wipe_timer.wait_time)


func pause():
	# Make music quieter. Pause the game.
	visible = true
	music_node.volume_db = -10
	get_tree().paused = true


func resume():
	# Check for currently quitting
	if !quit_fade_timer.is_stopped(): return
	# Resume + reset audio.
	visible = false
	music_node.volume_db = 0
	get_tree().paused = false


func quit():
	# Save current level etc etc
	PersistentData.save_game()
	screen_wipe_node.show()
	quit_fade_timer.start()

	
func quit_finish():
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")


func _on_resume_pressed():
	# Made this function by accident but i cant be bothered to change it
	resume()


func hide_wipe():
	if quit_fade_timer.is_stopped():
		screen_wipe_node.hide()


func show_options():
	# Check for currently quitting, then switch to option menu
	if !quit_fade_timer.is_stopped(): return
	$OptionMenu.show()
	$MenuItems.hide()


func _on_options_pressed():
	# See line 56
	show_options()
