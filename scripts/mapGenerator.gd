extends Node

var items := [
	["res://tiles/tilesScenes/turnLeft.tscn", 10],
	["res://tiles/tilesScenes/straightPathTile.tscn", 20],
	["res://tiles/tilesScenes/turnRight.tscn", 30],
]

var chosedTiles: Array = []

func _ready() -> void:
	randomize()
	for _i in range(10):
		var picked := chooseTile(items)
		chosedTiles.append(picked)
		print(picked)

func chooseTile(items: Array) -> String:
	var total := 0.0
	for item in items:
		total += float(item[1])

	var randValue := randf() * total
	var runningSum := 0.0
	for item in items:
		runningSum += float(item[1])
		if randValue <= runningSum:
			return String(item[0])
	return String(items[-1][0])
