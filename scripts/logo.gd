class_name Logo
extends Control
## Game logo drawn in code: slanted "EXTREME" over "RACING 3D" with speed bars.
## Use Logo.make(parent, scale) - 1.0 is about 520 x 170 pixels.

var k: float = 1.0
var _sz1: int = 84
var _sz2: int = 50


static func make(parent: Control, scale_k: float = 1.0) -> Logo:
    var l := Logo.new()
    l.k = scale_k
    l.custom_minimum_size = Vector2(520.0, 170.0) * scale_k
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l


func _draw() -> void:
    var font := ThemeDB.fallback_font
    var s1 := int(float(_sz1) * k)
    var s2 := int(float(_sz2) * k)
    var skew := Transform2D(Vector2(1.0, 0.0), Vector2(-0.22, 1.0), Vector2(14.0 * k, 0.0))
    draw_set_transform_matrix(skew)
    var base1 := 84.0 * k
    var w1 := font.get_string_size("EXTREME", HORIZONTAL_ALIGNMENT_LEFT, -1, s1).x
    # speed bars behind the text
    draw_rect(Rect2(0.0, base1 - 58.0 * k, w1 * 0.55, 5.0 * k), Color(0.1, 0.78, 1.0, 0.9))
    draw_rect(Rect2(0.0, base1 - 36.0 * k, w1 * 0.35, 4.0 * k), Color(0.75, 0.95, 1.0, 0.8))
    draw_rect(Rect2(0.0, base1 - 16.0 * k, w1 * 0.2, 3.0 * k), Color(0.75, 0.95, 1.0, 0.6))
    # EXTREME: white, thickened with a same-colour outline
    var pos1 := Vector2(8.0 * k, base1)
    draw_string_outline(font, pos1 + Vector2(0, 4.0 * k), "EXTREME", HORIZONTAL_ALIGNMENT_LEFT, -1, s1, int(8.0 * k), Color(0.0, 0.0, 0.0, 0.5))
    draw_string_outline(font, pos1, "EXTREME", HORIZONTAL_ALIGNMENT_LEFT, -1, s1, int(4.0 * k), Color.WHITE)
    draw_string(font, pos1, "EXTREME", HORIZONTAL_ALIGNMENT_LEFT, -1, s1, Color.WHITE)
    # underline bar
    draw_rect(Rect2(8.0 * k, base1 + 10.0 * k, w1, 6.0 * k), Color(0.1, 0.78, 1.0))
    # RACING in orange + 3D badge
    var base2 := 150.0 * k
    var pos2 := Vector2(8.0 * k, base2)
    var w2 := font.get_string_size("RACING", HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x
    draw_string_outline(font, pos2, "RACING", HORIZONTAL_ALIGNMENT_LEFT, -1, s2, int(3.0 * k), Color(0.1, 0.78, 1.0))
    draw_string(font, pos2, "RACING", HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color(0.1, 0.78, 1.0))
    var bx := 8.0 * k + w2 + 16.0 * k
    var bw := font.get_string_size("3D", HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x + 22.0 * k
    draw_rect(Rect2(bx, base2 - 42.0 * k, bw, 54.0 * k), Color(0.92, 0.97, 1.0))
    draw_string(font, Vector2(bx + 11.0 * k, base2 - 2.0 * k), "3D", HORIZONTAL_ALIGNMENT_LEFT, -1, s2, Color(0.02, 0.06, 0.14))
    draw_set_transform_matrix(Transform2D.IDENTITY)
