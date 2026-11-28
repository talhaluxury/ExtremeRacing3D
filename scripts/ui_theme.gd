class_name UITheme
extends RefCounted
## One modern look for the whole game: dark glass panels, rounded buttons,
## orange accent. Applied once to the root window (see boot.gd), so every
## screen picks it up. Buttons with theme_type_variation "PrimaryButton" get
## the orange racing-style slanted look.

const BG := Color(0.02, 0.035, 0.08)
const ACCENT := Color(0.10, 0.78, 1.0)
const ACCENT_2 := Color(0.62, 0.93, 1.0)
const TEXT := Color(0.96, 0.98, 1.0)
const TEXT_DIM := Color(0.66, 0.74, 0.88)
const GOOD := Color(0.35, 0.95, 0.55)

static var _theme: Theme = null


static func get_theme() -> Theme:
    if _theme == null:
        _theme = _build()
    return _theme


static func apply(tree: SceneTree) -> void:
    tree.root.theme = get_theme()


## "Frosted glass" nine-patch drawn in code: soft vertical gradient, a bright
## rim, a thin inner highlight and a glossy top half. Stretches to any size.
static func glass(top: Color, bottom: Color, rim: Color, gloss: float, radius: float = 20.0, margins: Vector4 = Vector4(22, 12, 22, 12)) -> StyleBoxTexture:
    var n := 64
    var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
    var c := float(n) * 0.5
    for y in n:
        for x in n:
            var px := absf(float(x) + 0.5 - c) - (c - 1.0 - radius)
            var py := absf(float(y) + 0.5 - c) - (c - 1.0 - radius)
            var d := Vector2(maxf(px, 0.0), maxf(py, 0.0)).length() + minf(maxf(px, py), 0.0) - radius
            var cover := clampf(0.5 - d, 0.0, 1.0)
            if cover <= 0.0:
                img.set_pixel(x, y, Color(0, 0, 0, 0))
                continue
            var t := float(y) / float(n - 1)
            var col := top.lerp(bottom, t)
            if y < n / 2:
                col = col.blend(Color(1, 1, 1, gloss * (1.0 - float(y) / (float(n) * 0.5))))
            var rim_w := clampf((d + 2.2) / 1.2, 0.0, 1.0)
            col = col.lerp(Color(rim.r, rim.g, rim.b, maxf(col.a, rim.a)), rim_w * rim.a)
            var inner := clampf(1.0 - absf(d + 4.0) / 1.2, 0.0, 1.0)
            if y < n / 2:
                col = col.blend(Color(1, 1, 1, inner * 0.22))
            col.a *= cover
            img.set_pixel(x, y, col)
    var sb := StyleBoxTexture.new()
    sb.texture = ImageTexture.create_from_image(img)
    sb.texture_margin_left = 24.0
    sb.texture_margin_right = 24.0
    sb.texture_margin_top = 24.0
    sb.texture_margin_bottom = 24.0
    sb.content_margin_left = margins.x
    sb.content_margin_top = margins.y
    sb.content_margin_right = margins.z
    sb.content_margin_bottom = margins.w
    return sb


static func _build() -> Theme:
    var t := Theme.new()
    t.default_font_size = 24
    var white := Color(1, 1, 1)

    # Button: clear glass
    t.set_stylebox("normal", "Button", glass(Color(1, 1, 1, 0.20), Color(0.6, 0.75, 1.0, 0.07), Color(1, 1, 1, 0.5), 0.16))
    t.set_stylebox("hover", "Button", glass(Color(1, 1, 1, 0.30), Color(0.6, 0.8, 1.0, 0.13), Color(1, 1, 1, 0.75), 0.2))
    t.set_stylebox("pressed", "Button", glass(Color(0.2, 0.8, 1.0, 0.55), Color(0.0, 0.45, 0.85, 0.45), Color(1, 1, 1, 0.9), 0.2))
    t.set_stylebox("disabled", "Button", glass(Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.18), 0.0))
    t.set_stylebox("focus", "Button", glass(Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(ACCENT.r, ACCENT.g, ACCENT.b, 1.0), 0.0))
    t.set_color("font_color", "Button", TEXT)
    t.set_color("font_hover_color", "Button", white)
    t.set_color("font_pressed_color", "Button", white)
    t.set_color("font_focus_color", "Button", white)
    t.set_color("font_disabled_color", "Button", Color(0.5, 0.56, 0.68))

    # Primary: bright cyan glass
    t.set_type_variation("PrimaryButton", "Button")
    t.set_stylebox("normal", "PrimaryButton", glass(Color(0.45, 0.92, 1.0, 0.92), Color(0.0, 0.5, 0.95, 0.9), Color(1, 1, 1, 0.85), 0.38))
    t.set_stylebox("hover", "PrimaryButton", glass(Color(0.65, 0.97, 1.0, 0.97), Color(0.1, 0.6, 1.0, 0.95), Color(1, 1, 1, 1.0), 0.42))
    t.set_stylebox("pressed", "PrimaryButton", glass(Color(0.0, 0.55, 0.9, 0.95), Color(0.0, 0.3, 0.7, 0.95), Color(1, 1, 1, 0.9), 0.15))
    t.set_stylebox("focus", "PrimaryButton", glass(Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(1, 1, 1, 1.0), 0.0))
    t.set_color("font_color", "PrimaryButton", white)
    t.set_color("font_hover_color", "PrimaryButton", white)
    t.set_color("font_pressed_color", "PrimaryButton", white)
    t.set_color("font_focus_color", "PrimaryButton", white)
    t.set_color("font_outline_color", "PrimaryButton", Color(0.0, 0.2, 0.45, 0.6))
    t.set_constant("outline_size", "PrimaryButton", 4)

    # Panels: larger glass sheets
    var panel := glass(Color(0.85, 0.93, 1.0, 0.16), Color(0.4, 0.55, 0.9, 0.08), Color(1, 1, 1, 0.35), 0.1, 26.0, Vector4(20, 14, 20, 14))
    t.set_stylebox("panel", "PanelContainer", panel)
    t.set_stylebox("panel", "Panel", panel)

    t.set_color("font_color", "Label", TEXT)

    # Progress bar
    var bg := glass(Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.3), 0.0, 20.0, Vector4(6, 4, 6, 4))
    t.set_stylebox("background", "ProgressBar", bg)
    var fill := glass(Color(0.55, 0.95, 1.0, 1.0), Color(0.0, 0.55, 1.0, 1.0), Color(1, 1, 1, 0.5), 0.35, 20.0, Vector4(6, 4, 6, 4))
    t.set_stylebox("fill", "ProgressBar", fill)
    t.set_color("font_color", "ProgressBar", white)

    # Sliders and scroll bars
    var slider := glass(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.3), 0.0, 20.0, Vector4(4, 5, 4, 5))
    t.set_stylebox("slider", "HSlider", slider)
    t.set_stylebox("grabber_area", "HSlider", fill)
    t.set_stylebox("grabber_area_highlight", "HSlider", fill)
    var grab := glass(Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.5), 0.1, 20.0, Vector4(4, 4, 4, 4))
    t.set_stylebox("grabber", "VScrollBar", grab)
    t.set_stylebox("grabber_highlight", "VScrollBar", grab)
    t.set_stylebox("grabber_pressed", "VScrollBar", fill)
    t.set_stylebox("scroll", "VScrollBar", slider)
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
