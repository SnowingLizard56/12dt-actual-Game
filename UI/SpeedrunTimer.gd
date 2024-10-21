extends Control


func _ready():
	PersistentData.connect("data_updated", update_visibility)
	update_visibility()


func _process(delta):
	var time = get_node("/root/PersistentData").time
	# Get time: is in seconds
	var seconds = floorf(time)
	# find diff in floor
	var ms = (time - seconds) * 1000
	# Divide, find diff in floor
	var minutes = floorf(seconds / 60.0)
	seconds -= minutes * 60
	# Divide, find diff in floor
	var hours = floorf(minutes / 60.0)
	minutes -= hours * 60
	
	# Display
	$Time.text = ""
	if hours:
		$Time.text += str(hours) + ":"
		if len(str(minutes)) == 1:
			$Time.text += "0"
		$Time.text += str(minutes) + ":"
	elif minutes:
		if len(str(minutes)) == 1:
			$Time.text += "0"
		$Time.text += str(minutes) + ":"
	if len(str(seconds)) == 1:
		$Time.text += "0"
	$Time.text += str(seconds) + "."
	$Ms.text = str(floorf(ms))


func update_visibility():
	visible = PersistentData.showtimer
