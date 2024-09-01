extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = get_node("/root/PersistentData").showtimer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var time = get_node("/root/PersistentData").time
	var seconds = floorf(time)
	var ms = time - seconds
	var minutes = floorf(seconds/60.0)
	seconds -= minutes*60
	var hours = floorf(minutes/60.0)
	minutes -= hours*60
	
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
	$Ms.text = str(floorf(ms*1000))
	
 
