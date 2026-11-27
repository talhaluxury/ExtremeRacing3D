extends Control
## Simple main menu: pick mode, track, car, difficulty and laps, then start.

const MODES := ["QUICK RACE", "TIME TRIAL", "FREE DRIVE"]
const DIFFS := ["EASY", "NORMAL", "HARD"]
const LAP_OPTIONS := [1, 2, 3, 5]

var _mode_btn: Button
var _track_btn: Button
var _car_btn: Button
var _diff_btn: Button
var _laps_btn: Button
var _coins: Label
var _rain_btn: Button


func _ready() -> void:
    AudioManager.play_music("menu")
    GameManager.career_event = -1
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.05, 0.08)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 8)
    center.add_child(outer)

    var title := Label.new()
    title.text = "EXTREME RACING 3D"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
    outer.add_child(title)

    _coins = Label.new()
    _coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _coins.add_theme_font_size_override("font_size", 24)
    outer.add_child(_coins)

    var cols := HBoxContainer.new()
    cols.add_theme_constant_override("separation", 24)
    outer.add_child(cols)
    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 8)
    cols.add_child(left)
    var right := VBoxContainer.new()
    right.add_theme_constant_override("separation", 8)
    cols.add_child(right)

    # left column: career + custom race
    var career := _make_button(left, _open_career, 520.0, 70.0)
    career.text = "CAREER"
    career.add_theme_font_size_override("font_size", 38)
    career.modulate = Color(0.6, 0.9, 1.0)
    _mode_btn = _make_button(left, _cycle_mode, 520.0)
    _track_btn = _make_button(left, _cycle_track, 520.0)
    _car_btn = _make_button(left, _cycle_car, 520.0)
    _diff_btn = _make_button(left, _cycle_diff, 520.0)
    _laps_btn = _make_button(left, _cycle_laps, 520.0)
    _rain_btn = _make_button(left, _toggle_rain, 520.0)
    var start := _make_button(left, _start, 520.0, 76.0)
    start.text = "START"
    start.add_theme_font_size_override("font_size", 40)
    start.modulate = Color(1.0, 0.85, 0.3)

    # right column: garage, settings, profile, rewards
    var garage := _make_button(right, _open_garage, 520.0, 70.0)
    garage.text = "GARAGE"
    garage.add_theme_font_size_override("font_size", 38)
    var settings := _make_button(right, _open_settings, 520.0, 70.0)
    settings.text = "SETTINGS"
    settings.add_theme_font_size_override("font_size", 38)
    var profile := _make_button(right, _open_profile, 520.0, 70.0)
    profile.text = "PROFILE"
    profile.add_theme_font_size_override("font_size", 38)
    var rewards := _make_button(right, _open_rewards, 520.0, 70.0)
    rewards.text = "REWARDS" + ("   (NEW!)" if SaveManager.daily_reward_available() else "")
    rewards.add_theme_font_size_override("font_size", 38)
    if SaveManager.daily_reward_available():
        rewards.modulate = Color(0.6, 1.0, 0.6)
    var log_btn := Button.new()
    log_btn.text = "LOG"
    log_btn.custom_minimum_size = Vector2(90, 48)
    log_btn.position = Vector2(12, 12)
    log_btn.pressed.connect(_show_log)
    add_child(log_btn)
    _refresh()


func _make_button(parent: Control, handler: Callable, width: float = 560.0, height: float = 52.0) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(width, height)
    b.add_theme_font_size_override("font_size", 28)
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


func _refresh() -> void:
    var gm := GameManager
    _mode_btn.text = "MODE:  " + MODES[gm.mode]
    _track_btn.text = "TRACK:  " + gm.TRACK_NAMES[gm.track_index]
    _car_btn.text = "CAR:  " + str(gm.get_car_data()["name"]).to_upper()
    _diff_btn.text = "AI LEVEL:  " + DIFFS[gm.difficulty]
    _laps_btn.text = "LAPS:  " + str(gm.laps)
    _diff_btn.disabled = gm.mode != gm.MODE_QUICK
    _laps_btn.disabled = gm.mode == gm.MODE_FREE
    _rain_btn.text = "WEATHER:  " + ("RAIN" if GameManager.rain else "CLEAR")
    _coins.text = "COINS: %d    BEST LAP: %s" % [SaveManager.coins, RaceHud.format_time(SaveManager.get_best_lap(gm.track_index))]


func _cycle_mode() -> void:
    GameManager.mode = (GameManager.mode + 1) % MODES.size()
    _refresh()


func _cycle_track() -> void:
    GameManager.track_index = GameManager.next_unlocked_track(GameManager.track_index)
    _refresh()


func _cycle_car() -> void:
    GameManager.select_car(GameManager.next_owned_car())
    _refresh()


func _cycle_diff() -> void:
    GameManager.difficulty = (GameManager.difficulty + 1) % DIFFS.size()
    _refresh()


func _cycle_laps() -> void:
    var i := LAP_OPTIONS.find(GameManager.laps)
    GameManager.laps = LAP_OPTIONS[(i + 1) % LAP_OPTIONS.size()]
    _refresh()


func _start() -> void:
    GameManager.career_event = -1
    if not SaveManager.is_track_unlocked(GameManager.track_index):
        GameManager.track_index = 0
    get_tree().change_scene_to_file("res://scenes/race.tscn")


func _open_career() -> void:
    get_tree().change_scene_to_file("res://scenes/career.tscn")


func _open_settings() -> void:
    get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _open_profile() -> void:
    get_tree().change_scene_to_file("res://scenes/profile.tscn")


func _open_rewards() -> void:
    get_tree().change_scene_to_file("res://scenes/rewards.tscn")


func _open_garage() -> void:
    get_tree().change_scene_to_file("res://scenes/garage.tscn")


func _show_log() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 50
    add_child(layer)
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.92)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(dim)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 20)
    layer.add_child(margin)
    var box := VBoxContainer.new()
    margin.add_child(box)
    var lines := ErrorLog.recent(20)
    var l := Label.new()
    l.text = "\n".join(lines) if not lines.is_empty() else "No errors in the log."
    l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
    l.size_flags_vertical = Control.SIZE_EXPAND_FILL
    l.add_theme_font_size_override("font_size", 17)
    box.add_child(l)
    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size = Vector2(0, 60)
    close.pressed.connect(layer.queue_free)
    box.add_child(close)


func _toggle_rain() -> void:
    GameManager.set_rain(not GameManager.rain)
    _refresh()
