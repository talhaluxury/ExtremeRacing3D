class_name UiKit
extends RefCounted
## Small helpers for the code-built menu screens (settings, profile, rewards).


## Dark background, BACK button and title. Returns the box to put content in.
static func screen(root: Control, title_text: String, back_scene: String = "res://scenes/main_menu.tscn") -> VBoxContainer:
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.05, 0.08)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 24)
    root.add_child(margin)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 10)
    margin.add_child(outer)

    var head := HBoxContainer.new()
    outer.add_child(head)
    var back := Button.new()
    back.text = "< BACK"
    back.custom_minimum_size = Vector2(180, 60)
    back.add_theme_font_size_override("font_size", 28)
    back.pressed.connect(func() -> void: root.get_tree().change_scene_to_file(back_scene))
    head.add_child(back)
    var title := Label.new()
    title.text = title_text
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 52)
    title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
    head.add_child(title)
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(180, 0)
    head.add_child(spacer)
    return outer


static func button(parent: Control, text: String, handler: Callable, width: float = 520.0, height: float = 56.0, font_size: int = 26) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(width, height)
    b.add_theme_font_size_override("font_size", font_size)
    b.pressed.connect(handler)
    parent.add_child(b)
    return b


static func label(parent: Control, text: String, font_size: int = 26, color: Color = Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    parent.add_child(l)
    return l
