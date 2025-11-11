extends Node3D

func _ready() -> void:
	var entry := get_node_or_null("Entry") as Node3D
	if entry == null:
		entry = find_child("Entry", true, false) as Node3D
	var exit := get_node_or_null("Exit") as Node3D
	if exit == null:
		exit = find_child("Exit", true, false) as Node3D

	print("[TILE]", name, "ready. entry:", entry, "exit:", exit)
	if entry != null:
		print("[TILE]", name, "entry.local:", entry.position, "entry.global:", entry.global_position)
	if exit != null:
		print("[TILE]", name, "exit.local:", exit.position, "exit.global:", exit.global_position)
