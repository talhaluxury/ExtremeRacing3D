# Testing report - Phase 7 (includes Phase 6 notes) (honest status)

## What was actually checked (static, no Godot available in the build environment)
- All `res://` paths in scripts, scenes and project.godot resolve, except the 8 optional car `.glb` files (loaded only if present, guarded by `ResourceLoader.exists`).
- No duplicate function names, no mixed tab/space indentation, brackets balanced in all 22 scripts.
- Workflow YAML parses; export presets contain `Android` (debug APK, arm64) and `Android AAB` (gradle, release).
- Project settings: Mobile renderer, landscape, ETC2/ASTC import enabled (required for Android export).

## Phase 7 static checks
- Same checks as above re-run on all scripts (brackets, indentation, duplicate functions, res:// paths): clean.
- New track layouts: minimum turn radius computed numerically (72 m or more, no self-crossing since radius stays positive around the centre).
- NOT verified: that the code parses in Godot 4.3, tilt axis/direction on a real phone, building/dune placement look, performance of 5 maps.

## Phase 8 static checks
- Brackets, indentation, duplicate functions, res:// paths re-checked: clean. Phase 7 debug APK built on GitHub Actions (reported by user); the game itself has not been run by me.

## NOT tested (needs Godot / a phone)
Nothing has been run. No game start, driving, nitro, drift, AI, garage, save, audio, touch-control, APK install or FPS test has happened. No performance numbers exist.

## How to test
1. Push to GitHub -> Actions -> "Android Build" -> Run workflow. Download `ExtremeRacing3D-debug-apk`.
2. If it fails, download `build-log` (import.log, export-apk.log) and send the error text.
3. Install the APK and tick `MANUAL_TEST_CHECKLIST.md`; note device model and FPS.

## Known unfinished
Tunnels/bridges, rain, motion blur, LOD meshes, real GLB car models (all 8 cars share one procedural body), AAB path unverified.
