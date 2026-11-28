extends Control
## Start-up check. Loads every script and scene once. If one fails (parse
## error), it is listed on screen together with the engine's error lines, so a
## problem can be read straight off the phone. If everything loads, the main
## menu opens at once.


func _ready() -> void:
    # Theme and logo are loaded by path so a script error in them cannot
    # stop this start-up check from running.
    var theme_script: Variant = load("res://scripts/ui_theme.gd")
    if theme_script is GDScript and (theme_script as GDScript).can_instantiate():
        (theme_script as GDScript).call("apply", get_tree())
    var bg := ColorRect.new()
    bg.color = Color(0.035, 0.045, 0.075)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 22)
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_child(col)
    var logo_script: Variant = load("res://scripts/logo.gd")
    if logo_script is GDScript and (logo_script as GDScript).can_instantiate():
        var logo: Control = (logo_script as GDScript).call("make", col, 1.2)
        logo.name = "Logo"
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(520, 14)
    bar.show_percentage = false
    bar.max_value = 1.0
    col.add_child(bar)
    var msg := Label.new()
    msg.text = "LOADING..."
    msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    msg.add_theme_font_size_override("font_size", 18)
    msg.add_theme_color_override("font_color", Color(0.62, 0.68, 0.8))
    col.add_child(msg)

    var started := Time.get_ticks_msec()
    var bad := PackedStringArray()
    var scripts := _files("res://scripts", ".gd")
    var scenes := _files("res://scenes", ".tscn")
    var total := float(scripts.size() + scenes.size())
    var done := 0.0
    for f in scripts:
        if f != "boot.gd":
            var s: Resource = load("res://scripts/" + f)
            if s == null or (s is GDScript and not (s as GDScript).can_instantiate()):
                bad.append("scripts/" + f)
        done += 1.0
        bar.value = done / total
        await get_tree().process_frame
    for f in scenes:
        if load("res://scenes/" + f) == null:
            bad.append("scenes/" + f)
        done += 1.0
        bar.value = done / total
        await get_tree().process_frame
    if not bad.is_empty():
        col.queue_free()
        _show_errors(bad)
        return
    msg.text = "READY"
    var left := 1.6 - float(Time.get_ticks_msec() - started) / 1000.0
    if left > 0.0:
        await get_tree().create_timer(left).timeout
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 0.0, 0.25)
    await tw.finished
    _go()


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
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
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
