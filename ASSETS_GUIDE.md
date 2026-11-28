# Adding real 3D car models (GLB)

The game already loads `assets/cars/<car_id>.glb` instead of the built-in blocky body.
The model is fitted automatically: scaled to the car's length, turned to drive forward,
centred and put on the ground. No numbers to set.

## 1. Where to download (free)
Always open the model's page and read its licence. Look for **CC0** (no credit needed) or **CC-BY** (credit the author in the game, e.g. in a Credits line).
| Source | What | Licence | Notes |
|---|---|---|---|
| poly.pizza | low-poly vehicles, GLB | CC0 / CC-BY per model | no login, small files, stylised |
| kenney.nl/assets (Car Kit) | low-poly cars | CC0 | stylised, very light |
| quaternius.com | low-poly packs | CC0 | stylised |
| sketchfab.com | most realistic cars | per model | free account needed; filter: Downloadable + CC0/CC-BY + Cars; choose "glTF" / ".glb". Many are copies of real brands (logos and shapes are trademarks) - fine for private testing, risky for a Play Store release |
| polyhaven.com, ambientcg.com | CC0 textures (asphalt, grass, rock) and sky HDRIs | CC0 | for a later environment upgrade |

## 2. What to pick (phone performance)
- Under about 60,000 triangles, textures 2048 px or smaller, file under about 15 MB.
- Car body with wheels in one model is fine. Wheels of an imported car do not spin or steer yet (the physics still work).
- Interior can be there but is not needed.

## 3. Put it in the game (Termux)
```bash
cd ~/ExtremeRacing3D
bash tools/add_car.sh supercar ~/storage/downloads/the_model.glb
git add .
git commit -m "Add supercar model"
git push
```
Car ids: sports_coupe, muscle_car, luxury_sedan, supercar, grand_tourer, electric, racing_supercar, hypercar.
Cars without a GLB keep the built-in body, so you can add them one by one.
GitHub refuses single files over 100 MB, so keep models small.

### Sketchfab zips (glTF + textures)
If the download is a `.zip` containing `scene.gltf`, `scene.bin` and a `textures` folder, give the zip itself to the script:
`bash tools/add_car.sh muscle_car ~/storage/downloads/model.zip`
Zips with only FBX / OBJ files, or with only textures and a nested "source" zip, do not work.
Read the licence file inside the zip (`license.txt`) before using a model.

## 4. If a car looks wrong
- Drives or shows backwards: in `scripts/car_data.gd` set `"glb_rotation_y": 180.0` for that car.
- Too big / small: change `"glb_scale"` (1.0 = the car's length from car_data, 1.1 = 10% longer).
- Floats or sinks: `"glb_offset": Vector3(0, 0.05, 0)`.
- Colour: imported models keep their own paint; garage paint colours apply only to the built-in body.

## 5. Add all downloaded cars at once (Termux)
```bash
cd ~/ExtremeRacing3D
bash tools/add_all.sh            # reads ~/storage/downloads/*.zip
git add . && git commit -m "Add car models" && git push origin main
```
The script guesses the car from the zip name (dodge/challenger -> muscle_car, mclaren -> racing_supercar,
ferrari -> supercar, porsche -> sports_coupe, lexus -> luxury_sedan ...), skips zips with no glb/gltf inside
and anything over 95 MB. For a zip it does not recognise: `bash tools/add_car.sh <car_id> <zip>`.

## 6. Wheels
`"glb_has_wheels"` in car_data.gd: `"auto"` (default) uses the model's own wheels if it has parts named
wheel/tire; `false` keeps the game's built-in wheels (use this for models without tyres, e.g. the Dodge);
`true` forces the model's wheels.
