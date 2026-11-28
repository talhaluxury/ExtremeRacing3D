class_name CarData
extends RefCounted
## Car definitions, ordered by tier (cheap -> expensive). The first car is free.
## To use a downloaded 3D model, put the .glb file in assets/cars/ with the
## file name given in "glb". If the file exists the game uses it instead of the
## built-in procedural body. Adjust glb_scale / glb_rotation_y / glb_offset so
## the model faces -Z (forward) and sits on the ground. Set glb_has_wheels to
## true if the model already contains its own wheels.
## "shape" tunes the procedural body (cabin size/position, wing, intakes...).
## "price" is in coins. Tune the economy here.

const MAX_LEVEL := 5
const UPGRADES := [
    {"key": "engine", "name": "ENGINE"},
    {"key": "tires", "name": "TIRES"},
    {"key": "nitro", "name": "NITRO"},
    {"key": "handling", "name": "HANDLING"},
]
const UPGRADE_COSTS := [300, 600, 1000, 1500, 2200]

const PAINTS = [
    {"name": "Crimson", "color": Color(0.82, 0.06, 0.07)},
    {"name": "Midnight Blue", "color": Color(0.04, 0.10, 0.45)},
    {"name": "Pearl White", "color": Color(0.93, 0.93, 0.95)},
    {"name": "Obsidian", "color": Color(0.02, 0.02, 0.03)},
    {"name": "Solar Orange", "color": Color(0.95, 0.42, 0.04)},
    {"name": "Lime", "color": Color(0.35, 0.85, 0.08)},
    {"name": "Violet", "color": Color(0.42, 0.10, 0.70)},
    {"name": "Gunmetal", "color": Color(0.25, 0.27, 0.30)},
    {"name": "Gold", "color": Color(0.85, 0.65, 0.12)},
    {"name": "Cyan", "color": Color(0.05, 0.70, 0.85)},
]

const WHEELS = [
    {"name": "Silver", "color": Color(0.85, 0.85, 0.9)},
    {"name": "Black", "color": Color(0.06, 0.06, 0.07)},
    {"name": "Gold", "color": Color(0.9, 0.7, 0.15)},
    {"name": "Red", "color": Color(0.85, 0.08, 0.08)},
    {"name": "Blue", "color": Color(0.1, 0.35, 0.95)},
    {"name": "Bronze", "color": Color(0.6, 0.35, 0.15)},
]

const CARS = [
    {
        "id": "sports_coupe", "name": "Sports Coupe", "price": 0,
        "glb": "res://assets/cars/sports_coupe.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.82, 0.06, 0.07),
        "mass": 1250.0, "accel": 9.5, "max_speed": 62.0, "grip": 24.0, "brake": 22.0,
        "length": 4.4, "width": 1.85, "spoiler": false,
        "shape": {"cab_len": 0.40, "cab_h": 0.40, "cab_z": 0.06},
    },
    {
        "id": "muscle_car", "name": "Muscle Car", "price": 1500,
        "glb": "res://assets/cars/muscle_car.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.05, 0.2, 0.75),
        "mass": 1650.0, "accel": 10.5, "max_speed": 70.0, "grip": 22.0, "brake": 21.0,
        "length": 4.8, "width": 1.95, "spoiler": false,
        "shape": {"cab_len": 0.34, "cab_h": 0.42, "cab_z": 0.12, "scoop": true, "fend_f": 0.26, "fend_r": 0.22},
    },
    {
        "id": "luxury_sedan", "name": "Luxury Sports Sedan", "price": 2500,
        "glb": "res://assets/cars/luxury_sedan.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.25, 0.27, 0.30),
        "mass": 1700.0, "accel": 10.0, "max_speed": 68.0, "grip": 25.0, "brake": 23.0,
        "length": 4.9, "width": 1.90, "spoiler": false,
        "shape": {"cab_len": 0.54, "cab_h": 0.44, "cab_z": 0.05, "cab_w": 0.86},
    },
    {
        "id": "supercar", "name": "Supercar", "price": 4000,
        "glb": "res://assets/cars/supercar.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.95, 0.6, 0.05),
        "mass": 1350.0, "accel": 12.0, "max_speed": 78.0, "grip": 28.0, "brake": 26.0,
        "length": 4.5, "width": 1.98, "spoiler": true,
        "shape": {"cab_len": 0.30, "cab_h": 0.32, "cab_z": 0.10, "intakes": true, "fend_f": 0.14, "fend_r": 0.28, "wing": 1},
    },
    {
        "id": "grand_tourer", "name": "Premium Grand Tourer", "price": 6000,
        "glb": "res://assets/cars/grand_tourer.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.85, 0.65, 0.12),
        "mass": 1600.0, "accel": 11.0, "max_speed": 74.0, "grip": 26.0, "brake": 24.0,
        "length": 4.7, "width": 1.95, "spoiler": false,
        "shape": {"cab_len": 0.44, "cab_h": 0.38, "cab_z": 0.10, "fend_f": 0.24, "fend_r": 0.20},
    },
    {
        "id": "electric", "name": "Electric Performance", "price": 8000,
        "glb": "res://assets/cars/electric.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.05, 0.70, 0.85),
        "mass": 1800.0, "accel": 13.5, "max_speed": 76.0, "grip": 27.0, "brake": 25.0,
        "length": 4.8, "width": 1.95, "spoiler": false,
        "shape": {"cab_len": 0.48, "cab_h": 0.40, "cab_z": 0.02, "cab_w": 0.88, "lightbar": true, "no_exhaust": true},
    },
    {
        "id": "racing_supercar", "name": "Racing Supercar", "price": 12000,
        "glb": "res://assets/cars/racing_supercar.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.42, 0.10, 0.70),
        "mass": 1200.0, "accel": 13.0, "max_speed": 84.0, "grip": 31.0, "brake": 29.0,
        "length": 4.5, "width": 2.0, "spoiler": true,
        "shape": {"cab_len": 0.28, "cab_h": 0.30, "cab_z": 0.12, "intakes": true, "fend_f": 0.12, "fend_r": 0.28, "wing": 2},
    },
    {
        "id": "hypercar", "name": "Hypercar", "price": 18000,
        "glb": "res://assets/cars/hypercar.glb", "glb_scale": 1.0, "glb_rotation_y": 0.0,
        "glb_offset": Vector3(0, 0, 0), "glb_has_wheels": true,
        "color": Color(0.93, 0.93, 0.95),
        "mass": 1300.0, "accel": 14.5, "max_speed": 92.0, "grip": 33.0, "brake": 31.0,
        "length": 4.6, "width": 2.02, "spoiler": true,
        "shape": {"cab_len": 0.26, "cab_h": 0.28, "cab_z": 0.14, "intakes": true, "fins": true, "fend_f": 0.10, "fend_r": 0.30, "wing": 2},
    },
]


static func index_of(id: String) -> int:
    for i in CARS.size():
        if CARS[i]["id"] == id:
            return i
    return -1


static func upgrade_cost(level: int) -> int:
    return UPGRADE_COSTS[clampi(level, 0, UPGRADE_COSTS.size() - 1)]
