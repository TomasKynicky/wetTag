extends Node3D

func _ready() -> void:
	var entry := get_node_or_null("Entry") as Node3D
	if entry == null:
		entry = find_child("Entry", true, false) as Node3D
	var exit := get_node_or_null("Exit") as Node3D
	if exit == null:
		exit = find_child("Exit", true, false) as Node3D
