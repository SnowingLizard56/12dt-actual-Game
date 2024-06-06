# oohhhhh no.
extends Control

@export var duplicate_node:Node2D

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position
var prev_position

func _ready():
	prev_position = position
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	load_branch(duplicate_node)

func _process(delta):
	# Maybe make this lock to grid?
	if dragging or hovered:
		mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		drag_offset = position - mouse_position
		dragging = true
	if dragging:
		prev_position = position
		position = round((mouse_position + drag_offset) / 8) * 8
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	if Input.is_action_just_released("Click"):
		dragging = false
	
func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

func load_branch(parent:Node2D):
	var k = parent.duplicate(8)
	$WindowFrame/Viewport.add_child(k)
	parent.hide()
	k.show()


func _on_node_2d_body_entered(body):
	if body.has_method("window_over"):
		body.window_over(self)


func _on_node_2d_body_exited(body):
	if body.has_method("window_being_over_is_over"):
		body.window_being_over_is_over(self)
