# Game.gd — Main game scene controller.
# Orchestrates vehicles, camera, cart snake, UI wiring, and menus.
extends Node2D

# ── Scenes ────────────────────────────────────────────────────────────────────
const TractorScene     := preload("res://scenes/Tractor.tscn")
const JeepScene        := preload("res://scenes/Jeep.tscn")
const HelicopterScene  := preload("res://scenes/Helicopter.tscn")
const CartScene        := preload("res://scenes/Cart.tscn")
const MinigameScene    := preload("res://scenes/Minigame.tscn")

# ── References (set in _ready) ────────────────────────────────────────────────
@onready var _map:        Node2D     = $Map
@onready var _vehicles:   Node2D     = $Vehicles
@onready var _carts:      Node2D     = $Carts
@onready var _camera:     Camera2D   = $Camera2D
@onready var _ui:         CanvasLayer = $UI

# ── Vehicle instances ─────────────────────────────────────────────────────────
var _tractor:    Vehicle = null
var _jeep:       Vehicle = null
var _helicopter: Vehicle = null
var _active:     Vehicle = null

# ── Cart snake ────────────────────────────────────────────────────────────────
var _cart_nodes: Array[Node2D] = []

# ── Menu state ────────────────────────────────────────────────────────────────
var _menu_open:      bool = false
var _actions_open:   bool = false
var _minigame_open:  bool = false

func _ready() -> void:
	_spawn_vehicles()
	_activate_vehicle(GameState.VehicleType.TRACTOR)

	# Wire UI signals
	_ui.open_menu_requested.connect(_show_menu)
	_ui.open_minigame_requested.connect(_open_minigame)
	_ui.open_actions_requested.connect(_show_actions_menu)
	_ui.do_action_requested.connect(_do_action)

	# Wire GameState signals
	GameState.vehicle_changed.connect(_on_vehicle_changed)
	GameState.cart_count_changed.connect(_on_cart_count_changed)

func _physics_process(_delta: float) -> void:
	if _active == null:
		return
	# Pass steering state from UI to the active vehicle
	_active.turning_left  = _ui.steering_left
	_active.turning_right = _ui.steering_right

	# Keep camera on active vehicle
	_camera.global_position = _active.global_position

# =============================================================================
# Vehicles
# =============================================================================

func _spawn_vehicles() -> void:
	_tractor    = TractorScene.instantiate()
	_jeep       = JeepScene.instantiate()
	_helicopter = HelicopterScene.instantiate()

	_tractor.global_position    = Vector2(0, 0)
	_jeep.global_position       = Vector2(60, 0)
	_helicopter.global_position = Vector2(120, 0)

	_vehicles.add_child(_tractor)
	_vehicles.add_child(_jeep)
	_vehicles.add_child(_helicopter)

	# Hide non-active vehicles
	_jeep.visible       = false
	_helicopter.visible = false

func _activate_vehicle(type: int) -> void:
	# Capture current active vehicle's position before switching
	var prev_pos := Vector2.ZERO
	if _active != null:
		prev_pos = _active.global_position

	_jeep.visible       = false
	_helicopter.visible = false
	_tractor.visible    = false

	match type:
		GameState.VehicleType.TRACTOR:
			_active = _tractor
		GameState.VehicleType.JEEP:
			_active = _jeep
		GameState.VehicleType.HELICOPTER:
			_active = _helicopter

	if _active:
		_active.visible = true
		# Move the newly active vehicle to where the previous one was
		if prev_pos != Vector2.ZERO:
			_active.global_position = prev_pos

func _on_vehicle_changed(type: int) -> void:
	_activate_vehicle(type)

# =============================================================================
# Cart snake management
# =============================================================================

func _on_cart_count_changed(count: int) -> void:
	# Add a new cart if count increased
	while _cart_nodes.size() < count:
		_add_cart()
	# Remove carts if count decreased (enemy stole one)
	while _cart_nodes.size() > count:
		var last: Node2D = _cart_nodes.pop_back()
		if is_instance_valid(last):
			last.queue_free()

func _add_cart() -> void:
	var cart: Area2D = CartScene.instantiate()
	# Follow the vehicle or the previous cart
	if _cart_nodes.is_empty():
		cart.follow_target = _tractor
	else:
		cart.follow_target = _cart_nodes.back()
	_cart_nodes.append(cart)
	_carts.add_child(cart)
	cart.stolen.connect(_on_cart_stolen.bind(cart))

func _on_cart_stolen(cart: Node2D) -> void:
	var idx := _cart_nodes.find(cart)
	if idx >= 0:
		_cart_nodes.remove_at(idx)
	# Relink the chain
	for i in _cart_nodes.size():
		if i == 0:
			_cart_nodes[i].follow_target = _tractor
		else:
			_cart_nodes[i].follow_target = _cart_nodes[i - 1]

# =============================================================================
# Menus / Actions
# =============================================================================

func _show_menu() -> void:
	if _menu_open:
		return
	_menu_open = true
	var panel := _make_popup_panel("📋 MENU", [
		"Drive Tractor", "Drive Jeep", "Drive Helicopter",
		"Field Info", "Close",
	], _on_menu_item)
	add_child(panel)

func _on_menu_item(item: String) -> void:
	_menu_open = false
	match item:
		"Drive Tractor":    GameState.current_vehicle = GameState.VehicleType.TRACTOR; GameState.vehicle_changed.emit(GameState.current_vehicle)
		"Drive Jeep":       GameState.current_vehicle = GameState.VehicleType.JEEP;    GameState.vehicle_changed.emit(GameState.current_vehicle)
		"Drive Helicopter": GameState.current_vehicle = GameState.VehicleType.HELICOPTER; GameState.vehicle_changed.emit(GameState.current_vehicle)

func _show_actions_menu() -> void:
	if _actions_open:
		return
	_actions_open = true
	var panel := _make_popup_panel("⚙ ACTIONS", [
		"Fire Water Cannon", "Deploy Vehicle", "Collect Nearby Hay", "Close",
	], _on_action_item)
	add_child(panel)

func _on_action_item(item: String) -> void:
	_actions_open = false
	match item:
		"Fire Water Cannon":
			if _active and _active.can_use_cannon:
				_active.fire_water_cannon()
		"Deploy Vehicle":
			if _active and _active.can_fly:
				_active.deploy_vehicle(TractorScene)

func _do_action() -> void:
	# Context-sensitive action based on current vehicle
	if _active and _active.can_use_cannon:
		_active.fire_water_cannon()

func _open_minigame() -> void:
	if _minigame_open:
		return
	if not GameState.can_afford(5, 3):
		_ui._notify("Not enough MP/SP (need 5MP + 3SP)")
		return
	_minigame_open = true
	var mg: Control = MinigameScene.instantiate()
	# Target the nearest field
	var nearest := _find_nearest_field()
	if nearest != null:
		mg.target_field = nearest.get("field_id") if nearest.get("field_id") != null else -1
	mg.minigame_closed.connect(func(): _minigame_open = false)
	add_child(mg)

func _find_nearest_field() -> Node:
	var best: Node   = null
	var best_d: float = INF
	for f in get_tree().get_nodes_in_group("fields"):
		var d: float = GameState.player_position.distance_to(f.global_position)
		if d < best_d:
			best_d = d
			best   = f
	return best

# =============================================================================
# Generic popup panel builder
# =============================================================================

func _make_popup_panel(title: String, items: Array, callback: Callable) -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color          = Color(0.05, 0.05, 0.12, 0.92)
	bg.size           = Vector2(320, 60 + items.size() * 48)
	bg.position       = Vector2(480, 200)
	panel.add_child(bg)

	var lbl := Label.new()
	lbl.text     = title
	lbl.position = bg.position + Vector2(12, 10)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	panel.add_child(lbl)

	for i in items.size():
		var btn := Button.new()
		btn.text     = items[i]
		btn.size     = Vector2(296, 40)
		btn.position = bg.position + Vector2(12, 48 + i * 44)
		btn.pressed.connect(func():
			callback.call(btn.text)
			panel.queue_free()
		)
		panel.add_child(btn)

	return panel
