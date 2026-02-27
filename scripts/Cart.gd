# Cart.gd — A hay cart that follows the vehicle or the cart in front of it.
# Carts form a snake. Enemies try to touch them to steal one.
extends Area2D

signal stolen

const CART_W      := 18.0
const CART_H      := 12.0
const CART_COLOR  := Color(0.55, 0.35, 0.12, 1.0)
const FOLLOW_DIST := 34.0
const FOLLOW_SPD  := 220.0

# The node this cart follows (Vehicle or another Cart)
var follow_target: Node2D = null

# History of positions from the followed node, used for smooth snake movement
var _pos_history: Array[Vector2] = []
var _rot_history: Array[float]   = []
const HISTORY_LEN := 40

func _ready() -> void:
	add_to_group("carts")
	collision_layer = 8
	collision_mask  = 16  # detect enemies (layer 16)

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-CART_W * 0.5, -CART_H * 0.5),
		Vector2( CART_W * 0.5, -CART_H * 0.5),
		Vector2( CART_W * 0.5,  CART_H * 0.5),
		Vector2(-CART_W * 0.5,  CART_H * 0.5),
	])
	poly.color = CART_COLOR
	add_child(poly)

	# Hay load on top
	var load := Polygon2D.new()
	load.polygon = PackedVector2Array([
		Vector2(-7, -6), Vector2(7, -6),
		Vector2(7,  6),  Vector2(-7, 6),
	])
	load.color = Color(0.95, 0.85, 0.20, 1.0)
	add_child(load)

	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CART_W, CART_H)
	cs.shape  = rect
	add_child(cs)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if follow_target == null:
		return

	# Record history from the followed node
	_pos_history.push_front(follow_target.global_position)
	_rot_history.push_front(follow_target.rotation)
	if _pos_history.size() > HISTORY_LEN:
		_pos_history.pop_back()
		_rot_history.pop_back()

	# Snap to the point in history that is ~FOLLOW_DIST behind the leader
	var accum := 0.0
	for i in range(1, _pos_history.size()):
		accum += _pos_history[i - 1].distance_to(_pos_history[i])
		if accum >= FOLLOW_DIST:
			global_position = _pos_history[i]
			rotation        = _rot_history[i]
			return

	# If not enough history yet, stay close
	if _pos_history.size() > 0:
		global_position = _pos_history[-1]

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		# Enemy steals this cart
		GameState.lose_cart()
		stolen.emit()
		queue_free()
