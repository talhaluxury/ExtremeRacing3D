extends Control
## Start-up check. Loads every script and scene once. If one fails (parse
## error), it is listed on screen together with the engine's error lines, so a
## problem can be read straight off the phone. If everything loads, the main
## menu opens at once.


func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.05, 0.05, 0.08)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var bad := PackedStringArray()
    for f in _files("res://scripts", ".gd"):
        if f == "boot.gd":
            continue
        var s: Resource = load("res://scripts/" + f)
        if s == null or (s is GDScript and not (s as GDScript).can_instantiate()):
            bad.append("scripts/" + f)
    for f in _files("res://scenes", ".tscn"):
        if load("res://scenes/" + f) == null:
            bad.append("scenes/" + f)
    if bad.is_empty():
        _go.call_deferred()
        return
    _show_errors(bad)


func _go() -> void:
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## File names in a folder. Exported builds list "name.gd.remap" / ".gdc", so the
## name is normalised back to "name.gd" / "name.tscn".
func _files(dir: String, ext: String) -> PackedStringArray:
    var out := PackedStringArray()
    for f in DirAccess.get_files_at(dir):
        var n := f
        if n.ends_with(".remap"):
            n = n.trim_suffix(".remap")
        if n.ends_with(".gdc"):
            n = n.trim_suffix(".gdc") + ".gd"
        if n.ends_with(".scn"):
            n = n.trim_suffix(".scn") + ".tscn"
        if n.ends_with(ext) and not out.has(n):
            out.append(n)
    return out


func _show_errors(bad: PackedStringArray) -> void:
    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 20)
    add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var title := Label.new()
    title.text = "STARTUP ERROR - send a screenshot of this screen"
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
    box.add_child(title)

    var files := Label.new()
    files.text = "Failed to load: " + ", ".join(bad)
    files.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    files.add_theme_font_size_override("font_size", 22)
    box.add_child(files)

    var log_label := Label.new()
    var lines := ErrorLog.recent(14)
    log_label.text = "\n".join(lines) if not lines.is_empty() else "(no log lines found)"
    log_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
    log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    log_label.add_theme_font_size_override("font_size", 17)
    log_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
    box.add_child(log_label)

    var b := Button.new()
    b.text = "TRY TO CONTINUE"
    b.custom_minimum_size = Vector2(0, 64)
    b.add_theme_font_size_override("font_size", 26)
    b.pressed.connect(_go)
    box.add_child(b)
