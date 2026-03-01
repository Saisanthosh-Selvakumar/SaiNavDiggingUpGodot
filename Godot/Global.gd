extends Node
var health: int = 0

func damage(amt):
	Global.health -= amt
