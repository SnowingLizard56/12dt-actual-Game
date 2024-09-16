extends Control

@export var splash_timer:Timer
@export var fade_timer:Timer
@export var menu_timer:Timer
@export var title:Node
@export var end_marker:Marker2D
@export var menu_holder:Control

@export var title_visibility:Gradient
@export var menu_visibility:Gradient

@onready var title_initial_pos = title.position
@onready var title_final_pos = end_marker.position

var button_sound = preload("res://SFX/MenuSelect.wav")
var skip = false

func _ready():
	ResourceLoader.load_threaded_request("res://Main.tscn")
	menu_holder.get_child(0).disabled = true
	menu_holder.get_child(1).disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !fade_timer.is_stopped():
		var time = fade_timer.time_left
		if Input.is_action_just_pressed("Skip") and $BlockSkipTimer.is_stopped():
			time = 0
			fade_timer.stop()
			splash_timer.start()
			skip = true
		title.modulate = title_visibility.sample(time/fade_timer.wait_time)
	elif !splash_timer.is_stopped():
		var time = splash_timer.time_left
		if Input.is_action_just_pressed("Skip") or skip:
			time = 0
			splash_timer.stop()
			menu_timer.start()
			menu_holder.show()
		var ratio = ease(1-(time/splash_timer.wait_time), -5)
		title.position = lerp(title_initial_pos, title_final_pos, ratio)
		title.scale = lerp(Vector2(2, 2), Vector2.ONE, ratio)
	elif !menu_timer.is_stopped():
		var time = menu_timer.time_left
		menu_holder.modulate = menu_visibility.sample(time/menu_timer.wait_time)
	
	if !$FadeToBlack/Timer.is_stopped():
		var time = $FadeToBlack/Timer.time_left
		$FadeToBlack.modulate = menu_visibility.sample(time/menu_timer.wait_time)

func start_clicked():
	$FadeToBlack/Timer.start()
	$FadeToBlack/Timer.connect("timeout", start_game)

func quit_clicked():
	$FadeToBlack/Timer.start()
	$FadeToBlack/Timer.connect("timeout", quit)
	
func menu_activate():
	menu_holder.get_child(0).disabled = false
	menu_holder.get_child(1).disabled = false

func start_game():
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://Main.tscn"))

func quit():
	get_tree().quit()
