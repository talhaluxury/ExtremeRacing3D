class_name ResultsScreen
extends CanvasLayer
## Overlay shown when the player finishes a race or time trial.

signal retry_pressed
signal next_pressed
signal menu_pressed

var _title: Label
var _body: Label
var _footer: Label
var _root: Control
var _next_btn: Button


func _ready() -> void:
    layer = 20
    _root = Control.new()
    _root.theme = UITheme.get_theme()
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.visible = false
    add_child(_root)

    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.7)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(dim)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(center)

    var panel := PanelContainer.new()
    center.add_child(panel)
    var margin := MarginContainer.new()
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 28)
    panel.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    margin.add_child(box)

    _title = _label(box, 46)
    _body = _label(box, 30)
    _footer = _label(box, 28)
    _footer.add_theme_color_override("font_color", UITheme.ACCENT_2)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_child(row)
    _button(row, "RETRY", retry_pressed)
    _next_btn = _button(row, "NEXT TRACK", next_pressed)
    _button(row, "MENU", menu_pressed)


func set_next(text: String, enabled: bool) -> void:
    _next_btn.text = text
    _next_btn.disabled = not enabled


func show_results(title: String, lines: PackedStringArray, footer: String) -> void:
    _title.text = title
    _body.text = "\n".join(lines)
    _footer.text = footer
    _root.visible = true


func _label(parent: Control, font_size: int) -> Label:
    var l := Label.new()
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    parent.add_child(l)
    return l


func _button(parent: Control, text: String, sig: Signal) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(200, 70)
    b.add_theme_font_size_override("font_size", 28)
    b.pressed.connect(func() -> void: sig.emit())
    parent.add_child(b)
    return b
