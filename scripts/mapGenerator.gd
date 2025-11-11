extends Node3D

var items := [
	["res://tiles/tilesScenes/turnLeft.tscn", 10],
	["res://tiles/tilesScenes/straightPathTile.tscn", 20],
	["res://tiles/tilesScenes/turnRight.tscn", 30],
]

@export var tiles_to_spawn: int = 10

var last_exit_pos: Vector3 = Vector3.ZERO
var has_last_exit: bool = false

var playersActiveTiles: Array[int] = []
var tile_player_counts: Dictionary = {}
var tiles_by_index: Dictionary = {}
var player_max_reached: Dictionary = {}

func _ready() -> void:
	randomize()
	for i in range(tiles_to_spawn):
		var path: String = choose_tile(items)
		var tile: Node3D = spawn_and_snap(path)
		tile.set_meta("tile_index", i)
		tiles_by_index[i] = tile
		print("Spawned tile index:", i, " path:", path)

		var area := tile.get_node_or_null("TriggerArea") as Area3D
		if area != null:
			if not area.playerEnterArea.is_connected(_on_player_enter_area):
				area.playerEnterArea.connect(_on_player_enter_area)
			if not area.playerLeaveArea.is_connected(_on_player_leave_area):
				area.playerLeaveArea.connect(_on_player_leave_area)

func _on_player_enter_area(tile_index: int, body: Node3D) -> void:
	var prev_count: int = 0
	if tile_player_counts.has(tile_index):
		prev_count = tile_player_counts[tile_index]
	var new_count: int = prev_count + 1
	tile_player_counts[tile_index] = new_count

	if prev_count == 0 and tile_index not in playersActiveTiles:
		playersActiveTiles.append(tile_index)

	var body_id: int = body.get_instance_id()
	var old_max: int
	if player_max_reached.has(body_id):
		old_max = player_max_reached[body_id]
	else:
		old_max = tile_index
	if tile_index > old_max:
		player_max_reached[body_id] = tile_index
	elif not player_max_reached.has(body_id):
		player_max_reached[body_id] = old_max

	print("Aktivní tiles:", playersActiveTiles)

func _on_player_leave_area(tile_index: int, body: Node3D) -> void:
	if not tile_player_counts.has(tile_index):
		return

	var prev_count: int = tile_player_counts[tile_index]
	var new_count: int = prev_count - 1

	if new_count <= 0:
		tile_player_counts.erase(tile_index)
		playersActiveTiles.erase(tile_index)

		var can_delete: bool = false
		if not player_max_reached.is_empty():
			can_delete = true
			for value in player_max_reached.values():
				var max_idx: int = value
				if max_idx <= tile_index:
					can_delete = false
					break

		if can_delete and tiles_by_index.has(tile_index):
			var tile: Node3D = tiles_by_index[tile_index]
			tiles_by_index.erase(tile_index)
			if is_instance_valid(tile):
				tile.queue_free()
	else:
		tile_player_counts[tile_index] = new_count

	print("Aktivní tiles:", playersActiveTiles)

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

func spawn_and_snap(path: String) -> Node3D:
	var res := load(path) as PackedScene
	var inst := res.instantiate() as Node3D
	add_child(inst)

	var entry := inst.get_node_or_null("Entry") as Node3D
	if entry == null:
		entry = inst.find_child("Entry", true, false) as Node3D
	var exit := inst.get_node_or_null("Exit") as Node3D
	if exit == null:
		exit = inst.find_child("Exit", true, false) as Node3D

	if entry == null:
		if has_last_exit:
			var offset_no_entry := last_exit_pos - inst.global_position
			inst.global_position += offset_no_entry
		else:
			inst.global_position = global_position
	else:
		var target_entry_pos: Vector3
		if has_last_exit:
			target_entry_pos = last_exit_pos
		else:
			target_entry_pos = global_position
		var current_entry_global: Vector3 = entry.global_position
		var offset: Vector3 = target_entry_pos - current_entry_global
		inst.global_position += offset

	if exit != null:
		last_exit_pos = exit.global_position
		has_last_exit = true

	return inst
