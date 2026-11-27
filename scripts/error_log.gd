class_name ErrorLog
extends RefCounted
## Reads the engine log (user://logs/godot.log, enabled in project.godot) so
## script errors can be shown on the phone screen without a computer.

const LOG_PATH := "user://logs/godot.log"


static func recent(max_lines: int = 16) -> PackedStringArray:
    var out := PackedStringArray()
    if not FileAccess.file_exists(LOG_PATH):
        return out
    var f := FileAccess.open(LOG_PATH, FileAccess.READ)
    if f == null:
        return out
    var text := f.get_as_text()
    f.close()
    for line in text.split("\n"):
        if "ERROR" in line or "Parse" in line or line.strip_edges().begins_with("at:"):
            out.append(line.strip_edges().left(170))
    if out.size() > max_lines:
        out = out.slice(out.size() - max_lines)
    return out
