# Building.gd — Base class for farm buildings (Barn, Mill).
# When the active vehicle enters the delivery zone with carts, deliver them.
extends StaticBody2D

class_name Building

@export var building_color: Color = Color(0.7, 0.2, 0.2, 1.0)
@export var label_text: String    = "BUILDING"

var _delivery_area: Area2D

func _ready() -> void:
	_build_visuals()
	_setup_delivery_area()

func _build_visuals() -> void:
	# Main body rectangle
	var body := ColorRect.new()
	body.size     = Vector2(80, 60)
	body.position = Vector2(-40, -50)
	body.color    = building_color
	add_child(body)

	# Roof triangle
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-44, -50), Vector2(44, -50), Vector2(0, -80),
	])
	roof.color = Color(building_color.r * 0.6, building_color.g * 0.6,
					   building_color.b * 0.6, 1.0)
	add_child(roof)

	# Label
	var lbl := Label.new()
	lbl.text               = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position          = Vector2(-40, -40)
	lbl.size              = Vector2(80, 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)

	# Collision
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 60)
	cs.position = Vector2(0, -20)
	cs.shape    = rect
	add_child(cs)

func _setup_delivery_area() -> void:
	_delivery_area = Area2D.new()
	_delivery_area.collision_layer = 0
	_delivery_area.collision_mask  = 1  # vehicle layer

	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size   = Vector2(120, 100)
	cs.position = Vector2(0, -20)
	cs.shape    = rect
	_delivery_area.add_child(cs)
	add_child(_delivery_area)

	_delivery_area.body_entered.connect(_on_vehicle_entered)

func _on_vehicle_entered(_body: Node) -> void:
	if GameState.cart_count > 0:
		_deliver()

# Override in subclass
func _deliver() -> void:
	pass
