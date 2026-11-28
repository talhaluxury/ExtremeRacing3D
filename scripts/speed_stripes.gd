class_name SpeedStripes
extends Control
## Faint slanted stripes that slowly drift, used behind menu screens.

var _t: float = 0.0


func _process(delta: float) -> void:
    _t += delta
    queue_redraw()


func _draw() -> void:
    var w := size.x
    var h := size.y
    for i in 7:
        var f := fposmod(_t * (0.02 + 0.006 * float(i)) + float(i) * 0.17, 1.0)
        var x := -0.3 * w + f * 1.6 * w
        var y := h * (0.1 + 0.13 * float(i))
        var len_px := w * (0.25 + 0.08 * float(i % 3))
        var col := Color(0.2, 0.7, 1.0, 0.05 + 0.02 * float(i % 3))
        var pts := PackedVector2Array([
            Vector2(x, y), Vector2(x + len_px, y),
            Vector2(x + len_px - 40.0, y + 8.0 + 3.0 * float(i % 3)), Vector2(x - 40.0, y + 8.0 + 3.0 * float(i % 3)),
        ])
        draw_colored_polygon(pts, col)
