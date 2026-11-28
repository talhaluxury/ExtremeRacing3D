class_name UITheme
extends RefCounted
## One modern look for the whole game: dark glass panels, rounded buttons,
## orange accent. Applied once to the root window (see boot.gd), so every
## screen picks it up. Buttons with theme_type_variation "PrimaryButton" get
## the orange racing-style slanted look.

const BG := Color(0.035, 0.045, 0.075)
const PANEL := Color(0.07, 0.09, 0.14, 0.88)
const BTN := Color(0.12, 0.15, 0.22, 0.92)
const BTN_HOVER := Color(0.17, 0.21, 0.31, 0.95)
const ACCENT := Color(1.0, 0.55, 0.05)
const ACCENT_2 := Color(1.0, 0.80, 0.15)
const TEXT := Color(0.94, 0.96, 1.0)
const TEXT_DIM := Color(0.62, 0.68, 0.80)
const GOOD := Color(0.35, 0.9, 0.5)

static var _theme: Theme = null


static func get_theme() -> Theme:
    if _theme == null:
        _theme = _build()
    return _theme


static func apply(tree: SceneTree) -> void:
    tree.root.theme = get_theme()


static func box(color: Color, radius: int = 12, border: Color = Color(1, 1, 1, 0.07), border_w: int = 1) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(radius)
    s.set_border_width_all(border_w)
    s.border_color = border
    s.content_margin_left = 18.0
    s.content_margin_right = 18.0
    s.content_margin_top = 10.0
    s.content_margin_bottom = 10.0
    s.anti_aliasing = true
    return s


static func _build() -> Theme:
    var t := Theme.new()
    t.default_font_size = 24

    # Button
    t.set_stylebox("normal", "Button", box(BTN))
    t.set_stylebox("hover", "Button", box(BTN_HOVER, 12, Color(1, 1, 1, 0.18)))
    t.set_stylebox("pressed", "Button", box(Color(0.9, 0.45, 0.05, 0.9), 12, ACCENT_2))
    t.set_stylebox("disabled", "Button", box(Color(0.1, 0.12, 0.17, 0.5), 12, Color(1, 1, 1, 0.03)))
    t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 12, ACCENT, 2))
    t.set_color("font_color", "Button", TEXT)
    t.set_color("font_hover_color", "Button", Color.WHITE)
    t.set_color("font_pressed_color", "Button", Color.WHITE)
    t.set_color("font_focus_color", "Button", Color.WHITE)
    t.set_color("font_disabled_color", "Button", Color(0.45, 0.5, 0.6))

    # Primary (orange, slanted)
    t.set_type_variation("PrimaryButton", "Button")
    var p := box(ACCENT, 10, ACCENT_2, 2)
    p.skew = Vector2(0.18, 0.0)
    p.shadow_color = Color(1.0, 0.45, 0.0, 0.35)
    p.shadow_size = 10
    t.set_stylebox("normal", "PrimaryButton", p)
    var ph := box(ACCENT_2, 10, Color.WHITE, 2)
    ph.skew = Vector2(0.18, 0.0)
    t.set_stylebox("hover", "PrimaryButton", ph)
    var pp := box(Color(0.85, 0.35, 0.0), 10, ACCENT_2, 2)
    pp.skew = Vector2(0.18, 0.0)
    t.set_stylebox("pressed", "PrimaryButton", pp)
    var pf := box(Color(0, 0, 0, 0), 10, Color.WHITE, 2)
    pf.skew = Vector2(0.18, 0.0)
    t.set_stylebox("focus", "PrimaryButton", pf)
    t.set_color("font_color", "PrimaryButton", Color(0.08, 0.04, 0.0))
    t.set_color("font_hover_color", "PrimaryButton", Color(0.08, 0.04, 0.0))
    t.set_color("font_pressed_color", "PrimaryButton", Color.WHITE)
    t.set_color("font_focus_color", "PrimaryButton", Color(0.08, 0.04, 0.0))

    # Panels
    t.set_stylebox("panel", "PanelContainer", box(PANEL, 16, Color(1, 1, 1, 0.08)))
    t.set_stylebox("panel", "Panel", box(PANEL, 16, Color(1, 1, 1, 0.08)))

    # Labels
    t.set_color("font_color", "Label", TEXT)

    # Progress bar
    var bg := box(Color(0.1, 0.12, 0.18, 0.9), 8, Color(1, 1, 1, 0.06))
    bg.content_margin_top = 4.0
    bg.content_margin_bottom = 4.0
    t.set_stylebox("background", "ProgressBar", bg)
    var fill := box(ACCENT, 8, Color(0, 0, 0, 0), 0)
    fill.bg_color = ACCENT
    t.set_stylebox("fill", "ProgressBar", fill)
    t.set_color("font_color", "ProgressBar", Color.WHITE)

    # Sliders
    var track := box(Color(0.14, 0.17, 0.25), 6, Color(0, 0, 0, 0), 0)
    track.content_margin_top = 5.0
    track.content_margin_bottom = 5.0
    t.set_stylebox("slider", "HSlider", track)
    var area := box(ACCENT, 6, Color(0, 0, 0, 0), 0)
    area.content_margin_top = 5.0
    area.content_margin_bottom = 5.0
    t.set_stylebox("grabber_area", "HSlider", area)
    t.set_stylebox("grabber_area_highlight", "HSlider", area)

    # Scroll bars
    var grab := box(Color(1, 1, 1, 0.25), 6, Color(0, 0, 0, 0), 0)
    t.set_stylebox("grabber", "VScrollBar", grab)
    t.set_stylebox("grabber_highlight", "VScrollBar", grab)
    t.set_stylebox("grabber_pressed", "VScrollBar", box(ACCENT, 6, Color(0, 0, 0, 0), 0))
    t.set_stylebox("scroll", "VScrollBar", box(Color(1, 1, 1, 0.04), 6, Color(0, 0, 0, 0), 0))
    return t


## Dark gradient backdrop with a few slanted accent stripes. Adds it as the
## first child so it sits behind everything else.
static func backdrop(parent: Control) -> void:
    var g := Gradient.new()
    g.set_color(0, Color(0.02, 0.025, 0.05))
    g.set_color(1, Color(0.09, 0.11, 0.2))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill_from = Vector2(0.0, 0.0)
    gt.fill_to = Vector2(0.7, 1.0)
    var tr := TextureRect.new()
    tr.texture = gt
    tr.stretch_mode = TextureRect.STRETCH_SCALE
    tr.set_anchors_preset(Control.PRESET_FULL_RECT)
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(tr)
    parent.move_child(tr, 0)
    var st := SpeedStripes.new()
    st.set_anchors_preset(Control.PRESET_FULL_RECT)
    st.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(st)
    parent.move_child(st, 1)
