extends Node
var health: int = 100
var multiplier: int = 1

func damage(amt):
	Global.health -= amt
	
func poiTaken():
	multiplier += 1
