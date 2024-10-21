# This is also technically unused. Oh well!!

extends Sprite2D

@export var frames:Array[Texture2D]
@export var alt_frames:Array[Texture2D]
@export var own_frame:int = 0: set=set__frame

var is_alt:bool:set=set_alt


func _ready():
	own_frame = 0


func set_alt(value):
	is_alt = value
	set__frame(own_frame)


func set__frame(value):
	# Update the current displayed frame.
	if is_alt and len(alt_frames) == len(frames):
		texture = alt_frames[value]
	else:
		texture = frames[value]
	own_frame = value
