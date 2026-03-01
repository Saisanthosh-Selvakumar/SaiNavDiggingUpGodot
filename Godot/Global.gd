extends Node
var health: int = 100

func damage(amt):
	Global.health -= amt
