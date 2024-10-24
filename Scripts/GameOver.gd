class_name DimensionalStabiliser extends Sprite2D

signal game_over


func _on_area_2d_body_entered(body):
	# Just read this. That's what it does.
	if body is Player:
		game_over.emit()
		$GameOverSound.play()
		get_parent().get_parent().get_node("GameplayMusic").stop()
