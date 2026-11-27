class_name SpeedLines
extends CanvasLayer
## Screen-edge speed streaks, shown at high speed and during nitro.

const CODE := """
shader_type canvas_item;
uniform float intensity = 0.0;
float h21(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
    vec2 c = UV - vec2(0.5);
    c.x *= 1.7;
    float d = length(c);
    float ang = atan(c.y, c.x);
    float seg = floor(ang * 48.0);
    float r = h21(vec2(seg, floor(TIME * 14.0)));
    float edge = smoothstep(0.38, 0.95, d);
    float a = step(0.7, r) * edge * intensity * 0.45;
    COLOR = vec4(1.0, 1.0, 1.0, a);
}
"""

var _mat: ShaderMaterial
var _rect: ColorRect


func _ready() -> void:
    layer = 3
    _rect = ColorRect.new()
    _rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader := Shader.new()
    shader.code = CODE
    _mat = ShaderMaterial.new()
    _mat.shader = shader
    _rect.material = _mat
    _rect.visible = false
    add_child(_rect)


func set_intensity(v: float) -> void:
    v = clampf(v, 0.0, 1.0)
    _rect.visible = v > 0.02
    _mat.set_shader_parameter("intensity", v)
