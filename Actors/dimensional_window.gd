# oohhhhh no.
extends Control

@export var duplicate_node:Node2D

var hovered:bool = false
var drag_offset:Vector2 = Vector2.ZERO
var dragging:bool = false
var mouse_position

func _ready():
	$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	load_branch(duplicate_node)

func _process(delta):
	# Maybe make this lock to grid?
	if dragging or hovered:
		mouse_position = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("Click") and hovered:
		drag_offset = position - mouse_position
		dragging = true
	elif Input.is_action_just_released("Click") and dragging:
		position = mouse_position + drag_offset
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
		dragging = false
	elif dragging:
		position = mouse_position + drag_offset
		$WindowFrame/Viewport/SubCamera.position = $WindowFrame.global_position
	
func _on_mouse_entered():
	hovered = true

func _on_mouse_exited():
	hovered = false

func load_branch(parent:Node2D):
	var k = parent.duplicate(8)
	$WindowFrame/Viewport.add_child(k)
	parent.hide()
