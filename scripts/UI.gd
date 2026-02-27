# UI.gd — HUD overlay with 4 diamond-shaped directional buttons.
#
# Button layout (bottom-right corner):
#           [Red / Up]
#  [Blue/L]            [Green/R]
#           [Yellow/D]
#
# Single-tap:
#   U → shift gear up     D → shift gear down
#   L/R → held = steer
# Two-button combos (within COMBO_TIMEOUT):
#   U+D → switch vehicle       L+R → open menu
#   U+R → open minigame        D+L → open actions menu
#   U+U → do action            D+D → stop / neutral gear
extends CanvasLayer

signal open_menu_requested
signal open_minigame_requested
signal open_actions_requested
signal do_action_requested

const COMBO_TIMEOUT := 0.35   # seconds to wait for a second press

# Steering state (queried by active vehicle in Game.gd)
var steering_left:  bool = false
var steering_right: bool = false

# ── Internal combo state ──────────────────────────────────────────────────────
var _first_press:      String = ""
var _first_press_time: float  = 0.0
var _combo_timer:      Timer

# ── Nodes ─────────────────────────────────────────────────────────────────────
var _speed_label:    Label
var _gear_label:     Label
var _mp_label:       Label
var _sp_label:       Label
var _cart_label:     Label
var _vehicle_label:  Label
var _notification:   Label
var _notif_timer:    Timer

func _ready() -> void:
	layer = 10
	_build_hud()
	_build_buttons()

	_combo_timer          = Timer.new()
	_combo_timer.one_shot = true
	_combo_timer.wait_time = COMBO_TIMEOUT
	_combo_timer.timeout.connect(_on_combo_timeout)
	add_child(_combo_timer)

	_notif_timer          = Timer.new()
	_notif_timer.one_shot = true
	_notif_timer.wait_time = 2.0
	_notif_timer.timeout.connect(func(): _notification.text = "")
	add_child(_notif_timer)

	# Connect to GameState signals
	GameState.gear_changed.connect(_on_gear_changed)
	GameState.mp_changed.connect(_on_mp_changed)
	GameState.sp_changed.connect(_on_sp_changed)
	GameState.cart_count_changed.connect(_on_cart_changed)
	GameState.vehicle_changed.connect(_on_vehicle_changed)

	_refresh_all()

# =============================================================================
# HUD panels
# =============================================================================

func _build_hud() -> void:
	# ── Top-left resource bar ─────────────────────────────────────────────────
	var res_bg := ColorRect.new()
	res_bg.color    = Color(0, 0, 0, 0.55)
	res_bg.size     = Vector2(260, 48)
	res_bg.position = Vector2(4, 4)
	add_child(res_bg)

	_mp_label = Label.new()
	_mp_label.position = Vector2(8, 8)
	_mp_label.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0))
	_mp_label.add_theme_font_size_override("font_size", 16)
	add_child(_mp_label)

	_sp_label = Label.new()
	_sp_label.position = Vector2(8, 28)
	_sp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_sp_label.add_theme_font_size_override("font_size", 16)
	add_child(_sp_label)

	_cart_label = Label.new()
	_cart_label.position = Vector2(140, 8)
	_cart_label.add_theme_color_override("font_color", Color(0.9, 0.65, 0.2))
	_cart_label.add_theme_font_size_override("font_size", 16)
	add_child(_cart_label)

	_vehicle_label = Label.new()
	_vehicle_label.position = Vector2(140, 28)
	_vehicle_label.add_theme_color_override("font_color", Color.WHITE)
	_vehicle_label.add_theme_font_size_override("font_size", 14)
	add_child(_vehicle_label)

	# ── Speed panel (bottom-left) ─────────────────────────────────────────────
	var spd_bg := ColorRect.new()
	spd_bg.color    = Color(0, 0, 0, 0.55)
	spd_bg.size     = Vector2(180, 48)
	spd_bg.position = Vector2(4, 668)
	add_child(spd_bg)

	_speed_label = Label.new()
	_speed_label.position = Vector2(8, 672)
	_speed_label.add_theme_font_size_override("font_size", 16)
	add_child(_speed_label)

	_gear_label = Label.new()
	_gear_label.position = Vector2(8, 692)
	_gear_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	_gear_label.add_theme_font_size_override("font_size", 14)
	add_child(_gear_label)

	# ── Notification bar (centre-bottom) ──────────────────────────────────────
	_notification = Label.new()
	_notification.position               = Vector2(400, 680)
	_notification.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	_notification.size                   = Vector2(480, 36)
	_notification.add_theme_font_size_override("font_size", 18)
	_notification.add_theme_color_override("font_color", Color.WHITE)
	add_child(_notification)

# =============================================================================
# Diamond button layout
# =============================================================================

# Button anchor: bottom-right cluster
const BTN_CX := 1160  # centre X of the diamond cluster
const BTN_CY :=  630  # centre Y of the diamond cluster
const BTN_GAP :=  58  # distance from centre to each button

func _build_buttons() -> void:
	# Up = Red
	_make_diamond_button("u", Color(0.85, 0.15, 0.15, 1.0),
		Vector2(BTN_CX, BTN_CY - BTN_GAP), "▲")
	# Down = Yellow
	_make_diamond_button("d", Color(0.90, 0.80, 0.05, 1.0),
		Vector2(BTN_CX, BTN_CY + BTN_GAP), "▼")
	# Left = Blue
	_make_diamond_button("l", Color(0.10, 0.30, 0.90, 1.0),
		Vector2(BTN_CX - BTN_GAP, BTN_CY), "◄")
	# Right = Green
	_make_diamond_button("r", Color(0.10, 0.70, 0.20, 1.0),
		Vector2(BTN_CX + BTN_GAP, BTN_CY), "►")

func _make_diamond_button(id: String, col: Color, pos: Vector2, icon: String) -> void:
	var btn := _DiamondButton.new(id, col, icon)
	btn.position = pos
	btn.pressed_signal.connect(_on_button_down.bind(id))
	btn.released_signal.connect(_on_button_up.bind(id))
	add_child(btn)

# =============================================================================
# Combo / single-press logic
# =============================================================================

func _on_button_down(id: String) -> void:
	# L / R → steering (held)
	if id == "l":
		steering_left = true
	if id == "r":
		steering_right = true

	var now := Time.get_ticks_msec() / 1000.0

	if _first_press == "":
		# First press of a potential combo
		_first_press      = id
		_first_press_time = now
		_combo_timer.start()
	else:
		# Second press — evaluate combo
		_combo_timer.stop()
		var combo := _first_press + id
		_first_press = ""
		_execute_combo(combo)

func _on_button_up(id: String) -> void:
	if id == "l":
		steering_left = false
	if id == "r":
		steering_right = false

func _on_combo_timeout() -> void:
	# No second press arrived — execute single action
	if _first_press != "":
		_execute_single(_first_press)
		_first_press = ""

func _execute_single(btn: String) -> void:
	match btn:
		"u":
			GameState.shift_gear_up()
			_notify("⬆ Gear %d" % GameState.current_gear)
		"d":
			GameState.shift_gear_down()
			_notify("⬇ Gear %d" % GameState.current_gear)
		# l / r are handled via steering_left / steering_right (held)

func _execute_combo(combo: String) -> void:
	match combo:
		"ud", "du":
			GameState.switch_vehicle()
			_notify("🚗 Switched to %s" % _vehicle_name(GameState.current_vehicle))
		"lr", "rl":
			open_menu_requested.emit()
			_notify("📋 Menu opened")
		"ur", "ru":
			open_minigame_requested.emit()
			_notify("🎮 Minigame!")
		"dl", "ld":
			open_actions_requested.emit()
			_notify("⚙ Actions menu")
		"uu":
			do_action_requested.emit()
			_notify("✅ Action!")
		"dd":
			GameState.stop_vehicle()
			_notify("🛑 Stopped")

# =============================================================================
# Signal handlers
# =============================================================================

func _on_gear_changed(_gear: int) -> void:
	_refresh_speed()

func _on_mp_changed(val: int) -> void:
	_mp_label.text = "🌙 MP: %d" % val

func _on_sp_changed(val: int) -> void:
	_sp_label.text = "⭐ SP: %d" % val

func _on_cart_changed(count: int) -> void:
	_cart_label.text = "🛒 Carts: %d" % count

func _on_vehicle_changed(_type: int) -> void:
	_vehicle_label.text = "🚗 %s" % _vehicle_name(GameState.current_vehicle)

func _refresh_speed() -> void:
	var spd := GameState.get_current_speed()
	if spd > 0.0:
		_speed_label.add_theme_color_override("font_color", Color.RED)
		_speed_label.text = "⬆ %.0f px/s" % spd
	elif spd < 0.0:
		_speed_label.add_theme_color_override("font_color", Color.YELLOW)
		_speed_label.text = "⬇ %.0f px/s" % abs(spd)
	else:
		_speed_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		_speed_label.text = "■ Stopped"
	_gear_label.text = "Gear %d" % GameState.current_gear

func _refresh_all() -> void:
	_on_mp_changed(GameState.moon_points)
	_on_sp_changed(GameState.star_points)
	_on_cart_changed(GameState.cart_count)
	_on_vehicle_changed(GameState.current_vehicle)
	_refresh_speed()

func _notify(msg: String) -> void:
	_notification.text = msg
	_notif_timer.start()

func _vehicle_name(t: int) -> String:
	match t:
		GameState.VehicleType.TRACTOR:    return "Tractor"
		GameState.VehicleType.JEEP:       return "Jeep"
		GameState.VehicleType.HELICOPTER: return "Helicopter"
	return "?"

# =============================================================================
# Inner class — diamond-shaped button drawn with Polygon2D / InputEvent
# =============================================================================

class _DiamondButton extends Node2D:
	signal pressed_signal
	signal released_signal

	const SIZE   := 24.0
	const COLORS := {
		"normal": Color(1, 1, 1, 0.85),
		"pressed": Color(1, 1, 1, 1.0),
	}

	var _id:     String
	var _col:    Color
	var _icon:   String
	var _pressed: bool = false
	var _lbl: Label

	func _init(id: String, col: Color, icon: String) -> void:
		_id   = id
		_col  = col
		_icon = icon

	func _ready() -> void:
		# Diamond polygon
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(0, -SIZE), Vector2(SIZE, 0),
			Vector2(0,  SIZE), Vector2(-SIZE, 0),
		])
		poly.color = _col
		add_child(poly)

		_lbl = Label.new()
		_lbl.text     = _icon
		_lbl.position = Vector2(-8, -11)
		_lbl.add_theme_font_size_override("font_size", 18)
		_lbl.add_theme_color_override("font_color", Color.WHITE)
		add_child(_lbl)

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var local := to_local(event.global_position)
			# Point-in-diamond test: |x| + |y| < SIZE
			if abs(local.x) + abs(local.y) < SIZE + 4:
				if event.pressed and not _pressed:
					_pressed = true
					scale    = Vector2(0.88, 0.88)
					pressed_signal.emit()
					get_viewport().set_input_as_handled()
				elif not event.pressed and _pressed:
					_pressed  = false
					scale     = Vector2.ONE
					released_signal.emit()
					get_viewport().set_input_as_handled()
		# Touch support
		elif event is InputEventScreenTouch:
			var local := to_local(event.position)
			if abs(local.x) + abs(local.y) < SIZE + 8:
				if event.pressed and not _pressed:
					_pressed = true
					scale    = Vector2(0.88, 0.88)
					pressed_signal.emit()
					get_viewport().set_input_as_handled()
				elif not event.pressed and _pressed:
					_pressed  = false
					scale     = Vector2.ONE
					released_signal.emit()
					get_viewport().set_input_as_handled()
