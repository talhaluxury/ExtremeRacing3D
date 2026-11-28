extends Control
## Career event list. Event n+1 opens when event n is passed.

var _coins: Label


func _ready() -> void:
    AudioManager.play_music("menu")
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.05, 0.08)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 24)
    add_child(margin)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 10)
    margin.add_child(outer)

    var head := HBoxContainer.new()
    outer.add_child(head)
    var back := Button.new()
    back.text = "< BACK"
    back.custom_minimum_size = Vector2(180, 60)
    back.add_theme_font_size_override("font_size", 28)
    back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
    head.add_child(back)
    var title := Label.new()
    title.text = "CAREER"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 52)
    title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
    head.add_child(title)
    _coins = Label.new()
    _coins.custom_minimum_size = Vector2(260, 0)
    _coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _coins.add_theme_font_size_override("font_size", 26)
    _coins.text = "COINS: %d" % SaveManager.coins
    head.add_child(_coins)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    outer.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)

    for i in CareerData.count():
        _add_event(list, i)


func _add_event(parent: Control, i: int) -> void:
    var e: Dictionary = CareerData.EVENTS[i]
    var open := SaveManager.career_event_open(i)
    var passed := SaveManager.career_passed(i)
    var diffs := ["EASY", "NORMAL", "HARD"]
    var req := "WIN" if int(e["req_pos"]) == 1 else "TOP %d" % int(e["req_pos"])
    var line1 := "%d.  %s" % [i + 1, e["name"]]
    var line2 := "%s  |  %d LAPS  |  AI %s  |  FINISH %s  |  %d COINS" % [
        TrackData.track_name(int(e["track"])), int(e["laps"]), diffs[int(e["diff"])], req, int(e["reward"])]
    var extra := PackedStringArray()
    if int(e["unlock_track"]) >= 0:
        extra.append("UNLOCKS " + TrackData.track_name(int(e["unlock_track"])))
    if str(e["unlock_car"]) != "":
        extra.append("UNLOCKS " + str(CarData.CARS[CarData.index_of(str(e["unlock_car"]))]["name"]).to_upper())
    if not extra.is_empty():
        line2 += "\n" + "  |  ".join(extra)
    var status := "LOCKED"
    if open:
        status = "PASSED  (best P%d)" % SaveManager.career_best_pos(i) if passed else "START"
    var b := Button.new()
    b.custom_minimum_size = Vector2(0, 100)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.add_theme_font_size_override("font_size", 24)
    b.text = "%s      [%s]\n%s" % [line1, status, line2]
    b.disabled = not open
    if open and not passed:
        b.modulate = Color(1.0, 0.9, 0.5)
    elif passed:
        b.modulate = Color(0.7, 1.0, 0.7)
    b.pressed.connect(func() -> void: start_event(i))
    parent.add_child(b)


func start_event(i: int) -> void:
    CareerData.apply(i)
    GameManager.start_race()
