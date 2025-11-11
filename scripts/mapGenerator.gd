extends Node3D

var items := [
	["res://tiles/tilesScenes/turnLeft.tscn", 10],
	["res://tiles/tilesScenes/straightPathTile.tscn", 20],
	["res://tiles/tilesScenes/turnRight.tscn", 30],
]

@export var tiles_to_spawn: int = 10

var last_exit_pos: Vector3 = Vector3.ZERO
var has_last_exit: bool = false

func _ready() -> void:
	randomize()
	for i in range(tiles_to_spawn):
		var path := choose_tile(items)
		spawn_and_snap(path)

func choose_tile(pool: Array) -> String:
	var total := 0.0
	for item in pool:
		total += float(item[1])

	var rand_value := randf() * total
	var running := 0.0
	for item in pool:
		running += float(item[1])
		if rand_value <= running:
			return String(item[0])

	return String(pool[-1][0])

func spawn_and_snap(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		print("Path not found:", path)
		return

	var res := load(path)
	if not (res is PackedScene):
		print("Resource is not PackedScene:", res)
		return

	var inst := (res as PackedScene).instantiate()
	if not (inst is Node3D):
		print("Instance is not Node3D:", inst)
		return

	var n3d := inst as Node3D
	add_child(n3d)

	var entry := n3d.get_node_or_null("Entry") as Node3D
	if entry == null:
		entry = n3d.find_child("Entry", true, false) as Node3D
	var exit := n3d.get_node_or_null("Exit") as Node3D
	if exit == null:
		exit = n3d.find_child("Exit", true, false) as Node3D

	print("Entry node:", entry, "Exit node:", exit)
	if entry != null:
		print("Entry local:", entry.position, "Entry global:", entry.global_position)
	if exit != null:
		print("Exit  local:", exit.position, "Exit  global:", exit.global_position)

	print("Before snap: has_last_exit:", has_last_exit, "last_exit_pos:", last_exit_pos)

	if entry == null:
		if has_last_exit:
			var offset_no_entry := last_exit_pos - n3d.global_position
			print("No Entry, using last_exit_pos, offset:", offset_no_entry)
			n3d.global_position += offset_no_entry
		else:
			print("No Entry and no last_exit_pos, snapping to generator position")
			n3d.global_position = global_position
	else:
		var target_entry_pos: Vector3
		if has_last_exit:
			target_entry_pos = last_exit_pos
		else:
			target_entry_pos = global_position
		var current_entry_global: Vector3 = entry.global_position
		var offset: Vector3 = target_entry_pos - current_entry_global
		print("Target_entry_pos:", target_entry_pos, "current_entry_global:", current_entry_global, "offset:", offset)
		n3d.global_position += offset

	print("After snap: tile global_position:", n3d.global_position)

	if exit != null:
		last_exit_pos = exit.global_position
		has_last_exit = true
		print("Updated last_exit_pos to:", last_exit_pos)
	else:
		print("No Exit, last_exit_pos unchanged:", last_exit_pos)
