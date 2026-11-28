class_name TouchControls
extends CanvasLayer
## On-screen buttons. TouchScreenButton supports multi-touch (steer + gas at
## the same time) and triggers the same input actions as the keyboard.

var _items: Array[Dictionary] = []


func _ready() -> void:
    layer = 10
    if GameManager.steer_wheel:
        _add_wheel()
    else:
        _add("steer_left", "<", Vector2(0, 1), Vector2(130, -120), 85.0, true)
        _add("steer_right", ">", Vector2(0, 1), Vector2(320, -120), 85.0, true)
    _add("brake", "BRAKE", Vector2(1, 1), Vector2(-330, -105), 80.0, false)
    _add("accelerate", "GAS", Vector2(1, 1), Vector2(-135, -135), 105.0, false)
    _add("nitro", "NITRO", Vector2(1, 1), Vector2(-110, -330), 65.0, false)
    _add("handbrake", "DRIFT", Vector2(1, 1), Vector2(-290, -250), 60.0, false)
    _add("reset_car", "RESET", Vector2(1, 0), Vector2(-75, 75), 45.0, false)
    _add("next_car", "CAR", Vector2(1, 0), Vector2(-185, 75), 45.0, false)
    _add("change_view", "VIEW", Vector2(1, 0), Vector2(-295, 75), 45.0, false)
    get_viewport().size_changed.connect(_layout)
    _layout()


func _disc(radius: float, alpha: float) -> GradientTexture2D:
    var g := Gradient.new()
    g.offsets = PackedFloat32Array([0.0, 0.88, 0.93, 1.0])
    g.colors = PackedColorArray([
        Color(1, 1, 1, alpha * 0.6),
        Color(1, 1, 1, alpha * 0.6),
        Color(1, 1, 1, alpha),
        Color(1, 1, 1, 0.0),
    ])
    var t := GradientTexture2D.new()
    t.gradient = g
    t.fill = GradientTexture2D.FILL_RADIAL
    t.fill_from = Vector2(0.5, 0.5)
    t.fill_to = Vector2(1.0, 0.5)
    t.width = int(radius * 2.0)
    t.height = int(radius * 2.0)
    return t


func _add(action: String, text: String, anchor: Vector2, offset: Vector2, radius: float, passby: bool) -> void:
    # user layout: button size, and left-handed mirror for the bottom (driving) buttons only
    radius *= GameManager.touch_scale
    offset *= GameManager.touch_scale
    if GameManager.touch_mirror and anchor.y > 0.5:
        anchor.x = 1.0 - anchor.x
        offset.x = -offset.x
    var btn := TouchScreenButton.new()
    btn.action = action
    btn.texture_normal = _disc(radius, 0.25)
    btn.texture_pressed = _disc(radius, 0.55)
    var shape := CircleShape2D.new()
    shape.radius = radius
    btn.shape = shape
    btn.passby_press = passby

    var label := Label.new()
    label.text = text
    label.size = Vector2(radius * 2.0, radius * 2.0)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", int(radius * 0.45))
    label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
    btn.add_child(label)

    add_child(btn)
    _items.append({"action": action, "node": btn, "anchor": anchor, "offset": offset, "radius": radius})


func _add_wheel() -> void:
    var anchor := Vector2(0, 1)
    var offset := Vector2(240, -215) * GameManager.touch_scale
    if GameManager.touch_mirror:
        anchor.x = 1.0
        offset.x = -offset.x
    var wheel := SteeringWheel.new()
    wheel.radius = 135.0 * GameManager.touch_scale
    add_child(wheel)
    _items.append({"action": "steer_wheel", "node": wheel, "anchor": anchor, "offset": offset, "radius": 0.0})


func _layout() -> void:
    var vs := get_viewport().get_visible_rect().size
    for item in _items:
        var r: float = item["radius"]
        var a: Vector2 = item["anchor"]
        var o: Vector2 = item["offset"]
        var node: Node2D = item["node"]
        node.position = Vector2(vs.x * a.x, vs.y * a.y) + o - Vector2(r, r)


func hide_action(action: String) -> void:
    for item in _items:
        if item["action"] == action:
            var node: Node2D = item["node"]
            node.visible = false
            node.process_mode = Node.PROCESS_MODE_DISABLED
