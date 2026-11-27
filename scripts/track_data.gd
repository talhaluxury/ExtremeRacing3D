class_name TrackData
extends RefCounted
## One entry per track: name, which sky preset (RaceEnvironment.PRESETS),
## ground colours and scenery style. `layout` is the index used by
## TrackBuilder._make_centerline.
##   tunnels: [start, end] road sample ranges (of 480) covered by a tunnel
##   scenery: "pine", "palm", "cactus" or "city"

const TRACKS := [
    {
        "name": "GRAND LOOP", "tunnels": [[60, 110]], "preset": 0, "scenery": "pine",
        "ground_base": Color(0.16, 0.34, 0.10), "ground_var": Color(0.06, 0.10, 0.04),
        "mountain": Color(0.38, 0.40, 0.46), "mountains": 14, "ocean": false,
    },
    {
        "name": "TECHNICAL CIRCUIT", "tunnels": [[300, 335]], "preset": 1, "scenery": "pine",
        "ground_base": Color(0.16, 0.34, 0.10), "ground_var": Color(0.06, 0.10, 0.04),
        "mountain": Color(0.38, 0.40, 0.46), "mountains": 14, "ocean": false,
    },
    {
        "name": "COASTAL HIGHWAY", "tunnels": [[200, 245]], "preset": 2, "scenery": "palm",
        "ground_base": Color(0.80, 0.72, 0.52), "ground_var": Color(0.08, 0.07, 0.05),
        "mountain": Color(0.55, 0.50, 0.42), "mountains": 6, "ocean": true,
    },
    {
        "name": "DESERT RUN", "tunnels": [[120, 160]], "preset": 3, "scenery": "cactus",
        "ground_base": Color(0.78, 0.58, 0.34), "ground_var": Color(0.08, 0.07, 0.05),
        "mountain": Color(0.62, 0.40, 0.26), "mountains": 14, "ocean": false,
    },
    {
        "name": "NIGHT CITY", "tunnels": [[90, 140], [350, 395]], "preset": 4, "scenery": "city",
        "ground_base": Color(0.05, 0.05, 0.07), "ground_var": Color(0.02, 0.02, 0.02),
        "mountain": Color(0.05, 0.06, 0.10), "mountains": 8, "ocean": false,
    },
]


static func count() -> int:
    return TRACKS.size()


static func track_name(i: int) -> String:
    return str(TRACKS[posmod(i, TRACKS.size())]["name"])


static func info(i: int) -> Dictionary:
    return TRACKS[posmod(i, TRACKS.size())]
