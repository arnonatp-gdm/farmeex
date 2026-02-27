# Minigame.gd — Word / image matching farming minigame.
# Player is shown an item (number, letter, colour, object, day) and must pick
# the correct word in the chosen language from 3 options.
# Winning hastens a field's spawn timer.
extends Control

signal minigame_closed

# ── Cost to play ──────────────────────────────────────────────────────────────
const COST_MP := 5
const COST_SP := 3

# ── Minigame database ─────────────────────────────────────────────────────────
const ITEMS: Array[Dictionary] = [
	# Numbers
	{"display": "1",  "en": "One",   "es": "Uno",       "he": "אחד"},
	{"display": "2",  "en": "Two",   "es": "Dos",       "he": "שתיים"},
	{"display": "3",  "en": "Three", "es": "Tres",      "he": "שלוש"},
	{"display": "4",  "en": "Four",  "es": "Cuatro",    "he": "ארבע"},
	{"display": "5",  "en": "Five",  "es": "Cinco",     "he": "חמש"},
	{"display": "6",  "en": "Six",   "es": "Seis",      "he": "שש"},
	{"display": "7",  "en": "Seven", "es": "Siete",     "he": "שבע"},
	{"display": "8",  "en": "Eight", "es": "Ocho",      "he": "שמונה"},
	{"display": "9",  "en": "Nine",  "es": "Nueve",     "he": "תשע"},
	{"display": "10", "en": "Ten",   "es": "Diez",      "he": "עשר"},
	# Letters
	{"display": "A", "en": "A", "es": "A", "he": "א"},
	{"display": "B", "en": "B", "es": "B", "he": "ב"},
	{"display": "C", "en": "C", "es": "C", "he": "ג"},
	{"display": "D", "en": "D", "es": "D", "he": "ד"},
	# Colours
	{"display": "■ RED",    "en": "Red",    "es": "Rojo",     "he": "אדום"},
	{"display": "■ BLUE",   "en": "Blue",   "es": "Azul",     "he": "כחול"},
	{"display": "■ GREEN",  "en": "Green",  "es": "Verde",    "he": "ירוק"},
	{"display": "■ YELLOW", "en": "Yellow", "es": "Amarillo", "he": "צהוב"},
	{"display": "■ WHITE",  "en": "White",  "es": "Blanco",   "he": "לבן"},
	# Objects
	{"display": "🌾 Hay",      "en": "Hay",     "es": "Heno",     "he": "קש"},
	{"display": "🏠 House",    "en": "House",   "es": "Casa",     "he": "בית"},
	{"display": "🌳 Tree",     "en": "Tree",    "es": "Árbol",    "he": "עץ"},
	{"display": "💧 Water",    "en": "Water",   "es": "Agua",     "he": "מים"},
	{"display": "🍎 Apple",    "en": "Apple",   "es": "Manzana",  "he": "תפוח"},
	{"display": "🚜 Tractor",  "en": "Tractor", "es": "Tractor",  "he": "טרקטור"},
	{"display": "🐔 Chicken",  "en": "Chicken", "es": "Pollo",    "he": "תרנגולת"},
	{"display": "🌽 Corn",     "en": "Corn",    "es": "Maíz",     "he": "תירס"},
	{"display": "🥕 Carrot",   "en": "Carrot",  "es": "Zanahoria","he": "גזר"},
	# Days
	{"display": "Monday",    "en": "Monday",    "es": "Lunes",     "he": "יום שני"},
	{"display": "Tuesday",   "en": "Tuesday",   "es": "Martes",    "he": "יום שלישי"},
	{"display": "Wednesday", "en": "Wednesday", "es": "Miércoles", "he": "יום רביעי"},
	{"display": "Thursday",  "en": "Thursday",  "es": "Jueves",    "he": "יום חמישי"},
	{"display": "Friday",    "en": "Friday",    "es": "Viernes",   "he": "יום שישי"},
	{"display": "Saturday",  "en": "Saturday",  "es": "Sábado",    "he": "שבת"},
	{"display": "Sunday",    "en": "Sunday",    "es": "Domingo",   "he": "יום ראשון"},
]

# ── State ─────────────────────────────────────────────────────────────────────
var language:     String = "en"   # "en", "es", or "he"
var target_field: int    = -1
var _current_item: Dictionary = {}
var _correct_answer: String   = ""
var _time_left: float         = 30.0
var _running: bool            = false
var _score: int               = 0

# ── UI nodes (built in _ready) ────────────────────────────────────────────────
var _item_label:   Label
var _timer_label:  Label
var _score_label:  Label
var _result_label: Label
var _answer_btns:  Array[Button] = []
var _lang_btns:    Array[Button] = []

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Semi-transparent background
	var bg := ColorRect.new()
	bg.color    = Color(0.05, 0.05, 0.10, 0.92)
	bg.size     = Vector2(560, 420)
	bg.position = Vector2(360, 150)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text     = "🌾 FARMING MINIGAME 🌾"
	title.position = Vector2(420, 158)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.20))
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)

	# Cost label
	var cost := Label.new()
	cost.text     = "Cost: %dMP + %dSP" % [COST_MP, COST_SP]
	cost.position = Vector2(420, 182)
	cost.add_theme_color_override("font_color", Color.LIGHT_CORAL)
	add_child(cost)

	# Language buttons
	var lang_row := HBoxContainer.new()
	lang_row.position = Vector2(370, 210)
	add_child(lang_row)
	for lang in ["en", "es", "he"]:
		var btn := Button.new()
		btn.text          = lang.to_upper()
		btn.custom_minimum_size = Vector2(60, 32)
		btn.pressed.connect(_on_lang_selected.bind(lang))
		lang_row.add_child(btn)
		_lang_btns.append(btn)

	# Item display
	_item_label = Label.new()
	_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_label.position = Vector2(360, 250)
	_item_label.size     = Vector2(560, 60)
	_item_label.add_theme_font_size_override("font_size", 36)
	_item_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_item_label)

	# Timer and score
	_timer_label = Label.new()
	_timer_label.position = Vector2(380, 315)
	_timer_label.add_theme_color_override("font_color", Color.ORANGE)
	add_child(_timer_label)

	_score_label = Label.new()
	_score_label.position = Vector2(820, 315)
	_score_label.add_theme_color_override("font_color", Color.CYAN)
	add_child(_score_label)

	# Answer buttons
	var ans_row := HBoxContainer.new()
	ans_row.position    = Vector2(370, 340)
	ans_row.add_theme_constant_override("separation", 12)
	add_child(ans_row)
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 50)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_answer_pressed.bind(i))
		ans_row.add_child(btn)
		_answer_btns.append(btn)

	# Result label
	_result_label = Label.new()
	_result_label.position = Vector2(470, 400)
	_result_label.add_theme_font_size_override("font_size", 18)
	add_child(_result_label)

	# Play / Close buttons
	var play_btn := Button.new()
	play_btn.text     = "▶ PLAY"
	play_btn.position = Vector2(530, 500)
	play_btn.size     = Vector2(100, 40)
	play_btn.pressed.connect(_start_round)
	add_child(play_btn)

	var close_btn := Button.new()
	close_btn.text     = "✖ CLOSE"
	close_btn.position = Vector2(650, 500)
	close_btn.size     = Vector2(100, 40)
	close_btn.pressed.connect(_close)
	add_child(close_btn)

func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	_timer_label.text = "⏱ %.1f s" % _time_left
	if _time_left <= 0.0:
		_end_round(false)

# ── Handlers ──────────────────────────────────────────────────────────────────

func _on_lang_selected(lang: String) -> void:
	language = lang

func _on_answer_pressed(idx: int) -> void:
	if not _running:
		return
	var chosen: String = _answer_btns[idx].text
	if chosen == _correct_answer:
		_end_round(true)
	else:
		_result_label.text = "✗ Wrong! Try again"
		_result_label.add_theme_color_override("font_color", Color.RED)

func _start_round() -> void:
	if not GameState.spend_resources(COST_MP, COST_SP):
		_result_label.text = "Not enough MP/SP!"
		_result_label.add_theme_color_override("font_color", Color.RED)
		return

	_current_item   = ITEMS[randi() % ITEMS.size()]
	_correct_answer = _current_item.get(language, _current_item["en"])
	_time_left      = 30.0
	_running        = true
	_result_label.text = ""

	_item_label.text = _current_item["display"]

	# Build 3 choices: correct + 2 random wrong ones
	var wrong_pool: Array[String] = []
	for it in ITEMS:
		var w: String = it.get(language, it["en"])
		if w != _correct_answer:
			wrong_pool.append(w)
	wrong_pool.shuffle()
	var choices: Array[String] = [_correct_answer, wrong_pool[0], wrong_pool[1]]
	choices.shuffle()
	for i in 3:
		_answer_btns[i].text = choices[i]

func _end_round(success: bool) -> void:
	_running = false
	if success:
		_score += 1
		_result_label.text = "✓ Correct! Field hastened by 20 s"
		_result_label.add_theme_color_override("font_color", Color.GREEN)
		GameState.add_mp(3)
		GameState.add_sp(1)
		if target_field >= 0:
			GameState.apply_field_haste(target_field, 20.0)
	else:
		_result_label.text = "⏰ Time's up!"
		_result_label.add_theme_color_override("font_color", Color.RED)
	_score_label.text = "Score: %d" % _score

func _close() -> void:
	minigame_closed.emit()
	queue_free()
