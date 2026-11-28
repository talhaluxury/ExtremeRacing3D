extends Control
## Main menu: a turning 3D car in the background, race setup on the left,
## garage / career / settings on the right.

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
var _car_name: Label
var _car_info: Label
var _stage: Showroom
var _shown_car: int = -1


func _ready() -> void:
    AudioManager.play_music("menu")
    GameManager.career_event = -1
    set_anchors_preset(Control.PRESET_FULL_RECT)

    # 3D stage behind everything
    var svc := SubViewportContainer.new()
    svc.stretch = true
    svc.set_anchors_preset(Control.PRESET_FULL_RECT)
    svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(svc)
    var sv := SubViewport.new()
    sv.own_world_3d = true
    sv.msaa_3d = Viewport.MSAA_2X if GameManager.graphics_quality > 0 else Viewport.MSAA_DISABLED
    sv.handle_input_locally = false
    svc.add_child(sv)
    _stage = Showroom.new()
    sv.add_child(_stage)

    # dark fade on the left so the text stays readable
    var g := Gradient.new()
    g.set_color(0, Color(0.02, 0.03, 0.06, 0.94))
    g.set_color(1, Color(0.02, 0.03, 0.06, 0.0))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill_from = Vector2(0.0, 0.0)
    gt.fill_to = Vector2(1.0, 0.0)
    var fade := TextureRect.new()
    fade.texture = gt
    fade.stretch_mode = TextureRect.STRETCH_SCALE
    fade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
    fade.anchor_right = 0.5
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fade)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 28)
    add_child(margin)
    var page := VBoxContainer.new()
    page.add_theme_constant_override("separation", 14)
    margin.add_child(page)

    # top bar: logo, coins, log
    var top := HBoxContainer.new()
    page.add_child(top)
    Logo.make(top, 0.6)
    var sp := Control.new()
    sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(sp)
    var chip := PanelContainer.new()
    chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    top.add_child(chip)
    _coins = Label.new()
    _coins.add_theme_font_size_override("font_size", 26)
    _coins.add_theme_color_override("font_color", UITheme.ACCENT_2)
    chip.add_child(_coins)
    var log_btn := Button.new()
    log_btn.text = "LOG"
    log_btn.custom_minimum_size = Vector2(80, 50)
    log_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    log_btn.add_theme_font_size_override("font_size", 18)
    log_btn.pressed.connect(_show_log)
    top.add_child(log_btn)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 20)
    page.add_child(body)

    # left card: race setup
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(430, 0)
    body.add_child(card)
    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 8)
    card.add_child(left)
    var head := Label.new()
    head.text = "RACE SETUP"
    head.add_theme_font_size_override("font_size", 20)
    head.add_theme_color_override("font_color", UITheme.TEXT_DIM)
    left.add_child(head)
    _mode_btn = _row(left, _cycle_mode)
    _track_btn = _row(left, _cycle_track)
    _car_btn = _row(left, _cycle_car)
    _diff_btn = _row(left, _cycle_diff)
    _laps_btn = _row(left, _cycle_laps)
    _rain_btn = _row(left, _toggle_rain)
    var start := Button.new()
    start.theme_type_variation = "PrimaryButton"
    start.text = "START RACE"
    start.custom_minimum_size = Vector2(0, 78)
    start.add_theme_font_size_override("font_size", 38)
    start.pressed.connect(_start)
    left.add_child(start)

    # centre: car name
    var mid := VBoxContainer.new()
    mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mid.alignment = BoxContainer.ALIGNMENT_END
    mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(mid)
    _car_name = Label.new()
    _car_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _car_name.add_theme_font_size_override("font_size", 40)
    _car_name.add_theme_color_override("font_color", Color.WHITE)
    _car_name.add_theme_constant_override("outline_size", 8)
    _car_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    mid.add_child(_car_name)
    _car_info = Label.new()
    _car_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _car_info.add_theme_font_size_override("font_size", 20)
    _car_info.add_theme_color_override("font_color", UITheme.TEXT_DIM)
    mid.add_child(_car_info)

    # right column
    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(300, 0)
    right.add_theme_constant_override("separation", 12)
    body.add_child(right)
    var career := _side_button(right, "CAREER", _open_career, true)
    career.custom_minimum_size = Vector2(300, 84)
    _side_button(right, "GARAGE", _open_garage, false)
    var daily := SaveManager.daily_reward_available()
    var rewards := _side_button(right, "REWARDS" + ("  (NEW!)" if daily else ""), _open_rewards, false)
    if daily:
        rewards.add_theme_color_override("font_color", UITheme.GOOD)
    _side_button(right, "PROFILE", _open_profile, false)
    _side_button(right, "SETTINGS", _open_settings, false)
    _refresh()


func _row(parent: Control, handler: Callable) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0, 58)
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.add_theme_font_size_override("font_size", 25)
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


func _side_button(parent: Control, text: String, handler: Callable, primary: bool) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(300, 68)
    b.add_theme_font_size_override("font_size", 32 if primary else 28)
    if primary:
        b.theme_type_variation = "PrimaryButton"
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


func _refresh() -> void:
    var gm := GameManager
    _mode_btn.text = "MODE     " + MODES[gm.mode]
    _track_btn.text = "TRACK    " + gm.TRACK_NAMES[gm.track_index]
    _car_btn.text = "CAR       " + str(gm.get_car_data()["name"]).to_upper()
    _diff_btn.text = "AI           " + DIFFS[gm.difficulty]
    _laps_btn.text = "LAPS      " + str(gm.laps)
    _diff_btn.disabled = gm.mode != gm.MODE_QUICK
    _laps_btn.disabled = gm.mode == gm.MODE_FREE
    _rain_btn.text = "WEATHER  " + ("RAIN" if GameManager.rain else "CLEAR")
    _coins.text = "  COINS  %d  " % SaveManager.coins
    var cd := gm.get_car_data()
    _car_name.text = str(cd["name"]).to_upper()
    _car_info.text = "TOP SPEED %d km/h     BEST LAP %s" % [int(float(cd["max_speed"]) * 3.6), RaceHud.format_time(SaveManager.get_best_lap(gm.track_index))]
    if _shown_car != gm.selected_car:
        _shown_car = gm.selected_car
        _stage.show_car(gm.selected_car)


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
    GameManager.start_race()


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


func _toggle_rain() -> void:
    GameManager.set_rain(not GameManager.rain)
    _refresh()


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
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
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
