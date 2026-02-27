# Mill.gd — Delivers carts for Star Points and Moon Points (inverted from barn).
# Formula: n*5 + (n-1) MP, n*2 + (n-1)*2 SP
extends Building

signal delivered(mp: int, sp: int)

func _ready() -> void:
	building_color = Color(0.55, 0.55, 0.58, 1.0)
	label_text     = "MILL"
	super()
	add_to_group("mills")

func _deliver() -> void:
	var n   := GameState.cart_count
	var mp  := n * 5 + (n - 1) * 1
	var sp  := n * 2 + (n - 1) * 2
	var got := GameState.deliver_to_mill()
	if got > 0:
		delivered.emit(mp, sp)
		_show_popup("+%dMP  +%dSP" % [mp, sp])

func _show_popup(text: String) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(-50, -100)
	lbl.add_theme_color_override("font_color", Color.CYAN)
	add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -40), 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)
