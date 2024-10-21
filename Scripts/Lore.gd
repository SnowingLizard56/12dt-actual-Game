extends Control

@export var label:Label
@export var vis_timer:Timer
@export var font_timer:Timer
@export var gradient:Gradient

var time_diff = 0


func write(text):
	# Update the written text
	label.text = text
	label.visible_ratio = 0
	time_diff = 0
	vis_timer.start()
	font_timer.start()
	label.label_settings.font_size = 1
	modulate = gradient.sample(1)
	$"RAHG !!! ITS GHONE".stop()


func _on_timer_timeout():
	# Roundabout way of increasing the number of characters visible by 1
	label.visible_ratio += 1.0 / len(label.text)
	if label.visible_ratio == 1:
		vis_timer.stop()
		$"RAHG !!! ITS GHONE".start()


func _on_font_timer_timeout():
	# Change font size
	label.label_settings.font_size += 1
	if label.label_settings.font_size == 12:
		font_timer.stop()


func _process(delta):
	if  !$"RAHG !!! ITS GHONE".is_stopped():
		# Fade out
		var r = ($"RAHG !!! ITS GHONE".time_left + time_diff) / $"RAHG !!! ITS GHONE".wait_time
		modulate = gradient.sample(r)


func screen_switched_midway():
	if !vis_timer.is_stopped():
		# New screen = new lore drop
		$"RAHG !!! ITS GHONE".start()
		vis_timer.stop()
	if $"RAHG !!! ITS GHONE".time_left > 1:
		# Reset timer on new screen
		time_diff = 1 - $"RAHG !!! ITS GHONE".time_left
