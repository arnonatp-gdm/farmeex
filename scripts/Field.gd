# Field.gd — Rectangular farm field that spawns hay every ~60 seconds.
# Spawn count = max(1, field_area / 5) distributed randomly inside the field.
extends Node2D

@export var field_width:  float = 120.0
@export var field_height: float = 160.0
@export var field_id:     int   = 0

const SPAWN_INTERVAL    := 60.0
# Divisor for computing spawn count from field area; tuned so a 3×4 field
# (~100×130 px) yields 1 hay sprite and a 10×15 field (~320×480 px) yields ~3.
const HAY_SPAWN_DIVISOR := 500.0
const FIELD_COLOR    := Color(0.22, 0.45, 0.12, 1.0)
const BORDER_COLOR   := Color(0.55, 0.38, 0.10, 1.0)

var _timer: float = SPAWN_INTERVAL
var _hay_scene: PackedScene

func _ready() -> void:
	add_to_group("fields")
	_hay_scene = load("res://scenes/Hay.tscn")

	# Visual — dark green rect with brown border
	var bg := ColorRect.new()
	bg.size           = Vector2(field_width, field_height)
	bg.position       = Vector2(-field_width * 0.5, -field_height * 0.5)
	bg.color          = FIELD_COLOR
	add_child(bg)

	# Dashed row lines for aesthetic
	var rows := int(field_height / 20)
	for r in rows:
		var line := ColorRect.new()
		line.size     = Vector2(field_width, 2)
		line.position = Vector2(-field_width * 0.5, -field_height * 0.5 + r * 20)
		line.color    = Color(0.18, 0.38, 0.10, 0.6)
		add_child(line)

func _process(delta: float) -> void:
	# Apply any field haste granted by minigames
	var haste := GameState.consume_haste(field_id)
	_timer -= delta + haste

	if _timer <= 0.0:
		_timer = SPAWN_INTERVAL
		_spawn_hay()

func _spawn_hay() -> void:
	var area   := field_width * field_height
	var count  := max(1, int(area / HAY_SPAWN_DIVISOR))
	var half_w := field_width  * 0.5 - 16.0
	var half_h := field_height * 0.5 - 16.0

	for _i in count:
		var hay: Area2D = _hay_scene.instantiate()
		hay.global_position = global_position + Vector2(
			randf_range(-half_w, half_w),
			randf_range(-half_h, half_h)
		)
		get_parent().add_child(hay)
