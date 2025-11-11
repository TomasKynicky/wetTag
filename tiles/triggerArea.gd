extends Area3D

signal playerEnterArea(index: int, body: Node3D)
signal playerLeaveArea(index: int, body: Node3D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var tile := get_parent() as Node3D
	if tile.has_meta("tile_index"):
		var idx: int = tile.get_meta("tile_index")
		playerEnterArea.emit(idx, body)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	var tile := get_parent() as Node3D
	if tile.has_meta("tile_index"):
		var idx: int = tile.get_meta("tile_index")
		playerLeaveArea.emit(idx, body)
