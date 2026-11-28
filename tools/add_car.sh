#!/data/data/com.termux/files/usr/bin/bash
# Usage: bash tools/add_car.sh <car_id> <model.glb | model.zip>
#  .glb -> copied to assets/cars/<car_id>.glb
#  .zip -> unpacked into assets/cars/<car_id>/ (must contain scene.gltf or a .glb/.gltf)
# car ids: sports_coupe muscle_car luxury_sedan supercar grand_tourer electric racing_supercar hypercar
set -e
ids="sports_coupe muscle_car luxury_sedan supercar grand_tourer electric racing_supercar hypercar"
if [ $# -ne 2 ] || ! echo " $ids " | grep -q " $1 "; then
  echo "Usage: bash tools/add_car.sh <car_id> <model.glb|model.zip>"; echo "car ids: $ids"; exit 1
fi
[ -f "$2" ] || { echo "File not found: $2"; exit 1; }
mkdir -p assets/cars
case "$2" in
  *.zip)
    rm -rf "assets/cars/$1"; mkdir -p "assets/cars/$1"
    unzip -q -o "$2" -d "assets/cars/$1"
    # if the zip had one top folder, move its content up
    if [ ! -f "assets/cars/$1/scene.gltf" ] && [ ! -f "assets/cars/$1/scene.glb" ]; then
      f=$(find "assets/cars/$1" -maxdepth 3 \( -name "*.glb" -o -name "*.gltf" \) | head -1)
      if [ -z "$f" ]; then echo "No .glb/.gltf inside this zip (FBX/OBJ is not supported). Removing."; rm -rf "assets/cars/$1"; exit 1; fi
      d=$(dirname "$f"); b=$(basename "$f")
      if [ "$d" != "assets/cars/$1" ]; then mv "$d"/* "assets/cars/$1"/; fi
      ext="${b##*.}"; [ "$b" != "scene.$ext" ] && mv "assets/cars/$1/$b" "assets/cars/$1/scene.$ext"
    fi
    du -sh "assets/cars/$1"; ls "assets/cars/$1" | head
    ;;
  *)
    cp "$2" "assets/cars/$1.glb"; ls -la "assets/cars/$1.glb" ;;
esac
echo "Done. Now: git add . && git commit -m 'Add $1 model' && git push"
