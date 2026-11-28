#!/data/data/com.termux/files/usr/bin/bash
# Usage: bash tools/add_all.sh [folder-with-zips]   (default ~/storage/downloads)
# Looks at every .zip, guesses the car from the file name (ferrari, mclaren,
# porsche, lexus, dodge ...), and puts it in the game with tools/add_car.sh.
# Models that are not usable (no glb/gltf inside) or bigger than 95 MB
# (GitHub limit is 100 MB per file) are skipped with a message.
dir="${1:-$HOME/storage/downloads}"
cd "$(dirname "$0")/.." || exit 1
used=" "
guess() {
  n=$(echo "$1" | tr 'A-Z' 'a-z')
  case "$n" in
    *challenger*|*dodge*|*mustang*|*camaro*|*charger*|*muscle*|*corvette*) echo muscle_car;;
    *mclaren*|*senna*|*720*|*765*|*speedtail*) echo racing_supercar;;
    *bugatti*|*chiron*|*veyron*|*koenigsegg*|*pagani*|*valkyrie*|*hypercar*|*rimac*) echo hypercar;;
    *ferrari*|*512*|*testarossa*|*lambo*|*aventador*|*huracan*|*f40*|*enzo*|*sf90*) echo supercar;;
    *tesla*|*taycan*|*electric*) echo electric;;
    *aston*|*bentley*|*grand*tour*) echo grand_tourer;;
    *lexus*|*sedan*|*m5*|*audi*|*mercedes*|*amg*) echo luxury_sedan;;
    *porsche*|*911*|*supra*|*skyline*|*gtr*|*nissan*|*coupe*) echo sports_coupe;;
    *) echo "";;
  esac
}
found=0
for z in "$dir"/*.zip; do
  [ -f "$z" ] || continue
  b=$(basename "$z")
  case "$b" in ExtremeRacing3D*) continue;; esac
  id=$(guess "$b")
  if [ -z "$id" ]; then echo "?  $b  -> car not recognised, add it by hand: bash tools/add_car.sh <car_id> $z"; continue; fi
  case "$used" in *" $id "*) echo "-  $b  -> $id is already filled, skipped"; continue;; esac
  if bash tools/add_car.sh "$id" "$z" >/dev/null 2>&1; then
    mb=$(du -sm "assets/cars/$id" | cut -f1)
    if [ "$mb" -gt 95 ]; then
      rm -rf "assets/cars/$id"; echo "X  $b  -> ${mb} MB is too big for GitHub, skipped"
    else
      used="$used$id "; found=$((found+1)); echo "OK $b  -> $id (${mb} MB)"
    fi
  else
    echo "X  $b  -> no glb/gltf model inside, skipped"
  fi
done
echo "Added $found car(s)."
echo "Next: git add . && git commit -m 'Add car models' && git push origin main"
