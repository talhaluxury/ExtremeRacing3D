class_name SteeringWheel
extends Node2D
## On-screen steering wheel. Put a finger on it and turn; it springs back to the
## centre when released. It drives the same steer_left / steer_right actions
## as the keyboard, with analog strength, and uses its own finger index so gas
## and brake can be pressed at the same time.

const MAX_ROT := 1.92   # about 110 degrees each way

var radius: float = 130.0
var rot: float = 0.0
var _finger: int = -1
var _grab: float = 0.0


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed and _finger == -1 and t.position.distance_to(global_position) <= radius * 1.25:
            _finger = t.index
            _grab = _angle(t.position) - rot
        elif (not t.pressed) and t.index == _finger:
            _finger = -1
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        if d.index == _finger:
            rot = clampf(wrapf(_angle(d.position) - _grab, -PI, PI), -MAX_ROT, MAX_ROT)


func _angle(p: Vector2) -> float:
    return (p - global_position).angle()


func _process(delta: float) -> void:
    if _finger == -1:
        rot = lerpf(rot, 0.0, minf(delta * 9.0, 1.0))
        if absf(rot) < 0.005:
            rot = 0.0
    var s := rot / MAX_ROT
    if s > 0.03:
        Input.action_press(&"steer_right", s)
        Input.action_release(&"steer_left")
    elif s < -0.03:
        Input.action_press(&"steer_left", -s)
        Input.action_release(&"steer_right")
    else:
        Input.action_release(&"steer_left")
        Input.action_release(&"steer_right")
    queue_redraw()


func _exit_tree() -> void:
    Input.action_release(&"steer_left")
    Input.action_release(&"steer_right")


func _draw() -> void:
    var r := radius
    draw_circle(Vector2.ZERO, r, Color(0.0, 0.05, 0.15, 0.28))
    draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.3, 0.85, 1.0, 0.35), 2.0, true)
    draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
    draw_arc(Vector2.ZERO, r * 0.88, 0.0, TAU, 64, Color(1, 1, 1, 0.5), r * 0.15, true)
    draw_arc(Vector2.ZERO, r * 0.96, 0.0, TAU, 64, Color(1, 1, 1, 0.7), 2.5, true)
    draw_line(Vector2.ZERO, Vector2(-r * 0.8, 0.0), Color(1, 1, 1, 0.5), r * 0.1, true)
    draw_line(Vector2.ZERO, Vector2(r * 0.8, 0.0), Color(1, 1, 1, 0.5), r * 0.1, true)
    draw_line(Vector2.ZERO, Vector2(0.0, r * 0.8), Color(1, 1, 1, 0.5), r * 0.1, true)
    draw_circle(Vector2.ZERO, r * 0.22, Color(0.1, 0.78, 1.0, 0.85))
    draw_rect(Rect2(-r * 0.05, -r * 0.99, r * 0.1, r * 0.22), Color(0.1, 0.78, 1.0))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
