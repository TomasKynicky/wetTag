extends Area3D

@export var waitTime: int = 5

var tileTimer: Timer

signal playerEnterArea(index: int, body: Node3D)
signal playerLeaveArea(index: int, body: Node3D)
signal timeOut(timeOut: bool)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	tileTimer = Timer.new()
	tileTimer.name = "TileTimer"
	add_child(tileTimer)
	tileTimer.one_shot = true
	tileTimer.wait_time = waitTime
	if not tileTimer.timeout.is_connected(_on_timer_timeout):
		tileTimer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body: Node3D) -> void:
	tileTimer.start()
	if not body.is_in_group("player"):
		return

	var tile := get_parent() as Node3D
	if tile.has_meta("tile_index"):
		var idx: int = tile.get_meta("tile_index")
		playerEnterArea.emit(idx, body)

func _on_body_exited(body: Node3D) -> void:
	tileTimer.stop()
	if not body.is_in_group("player"):
		return

	var tile := get_parent() as Node3D
	if tile.has_meta("tile_index"):
		var idx: int = tile.get_meta("tile_index")
		playerLeaveArea.emit(idx, body)

func _on_timer_timeout() -> void:
	timeOut.emit(true)
