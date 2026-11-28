extends Control
## Shown between the menu and a race: logo, track and car, progress bar and a tip.
## The race scene builds its track when it opens, so this screen stays up
## during that short freeze.

const RACE := "res://scenes/race.tscn"
const MIN_TIME := 1.8
const TIPS := [
    "Hold the drift button in a corner to build nitro.",
    "Brake early before sharp corners. Smooth lines are faster.",
    "Perfect start: press GAS just as the lights say GO.",
    "Upgrade tires and handling in the Garage for better grip.",
    "Rain makes the road slippery. Lift off the gas in corners.",
    "Finish career events in the top places to unlock new tracks.",
    "Collect the daily reward every day for bonus coins.",
]

var _bar: ProgressBar
var _t: float = 0.0
var _shown: float = 0.0
var _finishing: bool = false


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := ColorRect.new()
    bg.color = UITheme.BG
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    UITheme.backdrop(self)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 16)
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_child(col)
    Logo.make(col, 1.0)

    var track_name: String = GameManager.TRACK_NAMES[GameManager.track_index]
    var info := Label.new()
    info.text = "%s     |     %s" % [track_name, str(GameManager.get_car_data()["name"]).to_upper()]
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 28)
    info.add_theme_color_override("font_color", UITheme.ACCENT_2)
    col.add_child(info)

    _bar = ProgressBar.new()
    _bar.custom_minimum_size = Vector2(560, 16)
    _bar.show_percentage = false
    _bar.max_value = 100.0
    col.add_child(_bar)

    var tip := Label.new()
    tip.text = "TIP: " + str(TIPS[randi() % TIPS.size()])
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.custom_minimum_size = Vector2(700, 0)
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tip.add_theme_font_size_override("font_size", 20)
    tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
    col.add_child(tip)

    ResourceLoader.load_threaded_request(RACE)


func _process(delta: float) -> void:
    _t += delta
    if _finishing:
        return
    var prog: Array = []
    var st := ResourceLoader.load_threaded_get_status(RACE, prog)
    var ready_to_go := st == ResourceLoader.THREAD_LOAD_LOADED and _t >= MIN_TIME
    var target := minf(_t / MIN_TIME, 1.0) * 92.0
    if ready_to_go:
        target = 100.0
    _shown = lerpf(_shown, target, minf(delta * 6.0, 1.0))
    _bar.value = _shown
    if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        _finishing = true
        get_tree().change_scene_to_file(RACE)
        return
    if ready_to_go and _shown > 98.5:
        _finishing = true
        var packed := ResourceLoader.load_threaded_get(RACE) as PackedScene
        get_tree().change_scene_to_packed(packed)
