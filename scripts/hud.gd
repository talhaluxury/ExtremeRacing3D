class_name RaceHud
extends CanvasLayer
## Speedometer, lap timer, nitro bar and drift score.

var _speed: Label
var _unit: Label
var _info: Label
var _nitro_fill: ColorRect
var _drift: Label
var _drift_total: Label
var _msg: Label
var _msg_left: float = 0.0


func _ready() -> void:
    layer = 5
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    _speed = _make_label(root, 88, HORIZONTAL_ALIGNMENT_CENTER)
    _place(_speed, 0.5, 1.0, -150.0, -165.0, 150.0, -55.0)
    _speed.text = "0"

    _unit = _make_label(root, 28, HORIZONTAL_ALIGNMENT_CENTER)
    _place(_unit, 0.5, 1.0, -150.0, -60.0, 150.0, -20.0)
    _unit.text = "km/h"

    _info = _make_label(root, 30, HORIZONTAL_ALIGNMENT_LEFT)
    _place(_info, 0.0, 0.0, 24.0, 16.0, 500.0, 210.0)

    _msg = _make_label(root, 130, HORIZONTAL_ALIGNMENT_CENTER)
    _place(_msg, 0.5, 0.5, -400.0, -170.0, 400.0, 20.0)

    # nitro bar (top centre)
    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.55)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)
    _place(bg, 0.5, 0.0, -204.0, 16.0, 204.0, 42.0)
    _nitro_fill = ColorRect.new()
    _nitro_fill.color = Color(0.2, 0.85, 1.0)
    _nitro_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(_nitro_fill)
    _place(_nitro_fill, 0.5, 0.0, -200.0, 20.0, 200.0, 38.0)
    var nl := _make_label(root, 20, HORIZONTAL_ALIGNMENT_CENTER)
    _place(nl, 0.5, 0.0, -200.0, 42.0, 200.0, 68.0)
    nl.text = "NITRO"

    _drift = _make_label(root, 40, HORIZONTAL_ALIGNMENT_CENTER)
    _place(_drift, 0.5, 0.0, -250.0, 72.0, 250.0, 122.0)
    _drift_total = _make_label(root, 22, HORIZONTAL_ALIGNMENT_CENTER)
    _place(_drift_total, 0.5, 0.0, -250.0, 122.0, 250.0, 152.0)
    _drift_total.text = "DRIFT SCORE 0"


func set_speed(kmh: float) -> void:
    _speed.text = str(int(round(kmh)))


func set_race_info(pos: int, total: int, lap: int, laps: int, current: float, best: float) -> void:
    var t := ""
    if total > 1:
        t += "POS %d/%d\n" % [pos, total]
    if laps > 0:
        t += "LAP %d/%d\n" % [lap, laps]
    else:
        t += "LAP %d\n" % lap
    t += "TIME %s\nBEST %s" % [format_time(current), format_time(best)]
    _info.text = t


func show_message(text: String, duration: float = 0.0) -> void:
    _msg.text = text
    _msg_left = duration


func _process(delta: float) -> void:
    if _msg_left > 0.0:
        _msg_left -= delta
        if _msg_left <= 0.0:
            _msg.text = ""


func set_nitro(ratio: float, active: bool) -> void:
    _nitro_fill.offset_right = -200.0 + 400.0 * clampf(ratio, 0.0, 1.0)
    _nitro_fill.color = Color(1.0, 0.55, 0.1) if active else Color(0.2, 0.85, 1.0)


func update_drift(d: DriftSystem) -> void:
    if d.drifting:
        _drift.text = "DRIFT x%d   %d" % [int(d.multiplier), int(d.current_points)]
    elif d.since_bank < 2.0 and d.last_bank > 0.0:
        _drift.text = "+%d" % int(d.last_bank)
    else:
        _drift.text = ""
    _drift_total.text = "DRIFT SCORE %d" % int(d.total_score)


static func format_time(t: float) -> String:
    if t < 0.0:
        return "--:--.-"
    var m := int(t / 60.0)
    var sec := t - float(m) * 60.0
    return "%d:%04.1f" % [m, sec]


func _make_label(parent: Control, font_size: int, align: HorizontalAlignment) -> Label:
    var l := Label.new()
    l.horizontal_alignment = align
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 8)
    parent.add_child(l)
    return l


func _place(c: Control, ax: float, ay: float, l: float, t: float, r: float, b: float) -> void:
    c.anchor_left = ax
    c.anchor_right = ax
    c.anchor_top = ay
    c.anchor_bottom = ay
    c.offset_left = l
    c.offset_top = t
    c.offset_right = r
    c.offset_bottom = b
