# Hay.gd — Collectible hay sprite spawned by a Field.
# When the active (tractor) vehicle overlaps it, it is collected.
extends Area2D

signal collected

const HAY_COLOR  := Color(0.95, 0.85, 0.20, 1.0)
const HAY_RADIUS := 14.0

var _bob_time: float = 0.0

func _ready() -> void:
	add_to_group("hay")
	collision_layer = 4
	collision_mask  = 1  # detect vehicles (layer 1)

	# Draw a star-like polygon
	var poly := Polygon2D.new()
	var pts: Array[Vector2] = []
	var spikes := 6
	for i in spikes * 2:
		var a := i * TAU / (spikes * 2)
		var r := HAY_RADIUS if i % 2 == 0 else HAY_RADIUS * 0.5
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	poly.polygon = PackedVector2Array(pts)
	poly.color   = HAY_COLOR
	add_child(poly)

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = HAY_RADIUS
	cs.shape = circle
	add_child(cs)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time += delta
	scale = Vector2.ONE * (1.0 + sin(_bob_time * 3.0) * 0.06)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("tractor") and GameState.current_vehicle == GameState.VehicleType.TRACTOR:
		GameState.collect_hay()
		collected.emit()
		queue_free()
