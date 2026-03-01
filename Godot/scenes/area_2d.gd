extends Area2D

func _on_body_entered(body):
	Global.damage(10)
	print("Player hit! Health reduced.")
