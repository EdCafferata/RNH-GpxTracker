#!/bin/zsh
# App Store-screenshots voor RNH Tracker: 11 talen × (iPhone 6,9" + iPad 13" + iPhone Duo) × 3 schermen.
# Gebruik: AppStore/maak-screenshots.sh   (duurt ±45 min; resultaat in AppStore/Screenshots/<locale>/<toestel>/)
set -e
cd "${0:A:h}/.."
DD=${DD:-$HOME/rnh-shots-dd}; OUT=$(mktemp -d)
BUNDLE=info.cafferata.RnhGpxTracker
typeset -A LOC=(nl nl-NL en en-US)   # de App Store-listing heeft alleen NL en EN
toestel() { # naam type
  local id=$(xcrun simctl list devices available | grep -F "$1 (" | head -1 | grep -oE '[0-9A-F-]{36}')
  [[ -z $id ]] && id=$(xcrun simctl create "$1" "$2")
  echo $id
}
typeset -A DEV=(
  "iPhone 6.9 Display" "$(toestel 'iPhone 17 Pro Max' com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max)"
  "iPad Pro 13 Display" "$(toestel 'iPad Pro 13-inch (M5)' com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)"
  "iPhone Duo Display" "$(toestel 'iPhone Duo' com.apple.CoreSimulator.SimDeviceType.iPhone-Duo)"
)
for slot id in ${(kv)DEV}; do
  xcrun simctl boot $id 2>/dev/null || true; xcrun simctl bootstatus $id >/dev/null
  xcrun simctl status_bar $id override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  xcodebuild build-for-testing -project OpenRHNTracker.xcodeproj -scheme OpenRHNTracker \
    -destination "id=$id" -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO -quiet
  xcrun simctl install $id "$DD/Build/Products/Debug-iphonesimulator/OpenRHNTracker.app"
  xcrun simctl privacy $id grant location-always $BUNDLE || true
  for lang loc in ${(kv)LOC}; do
    xcrun simctl location $id clear || true
    # Route: uit de haven van IJmuiden de Noordzee op, ±6 knopen.
    xcrun simctl location $id start --speed=3 52.4634,4.5790 52.4652,4.5600 52.4675,4.5400 52.4700,4.5200 &
    LOCPID=$!
    TEST_RUNNER_SCREENSHOT_DIR=$OUT TEST_RUNNER_SCREENSHOT_LANG=$lang TEST_RUNNER_SCREENSHOT_PREFIX="$slot~$loc" \
      xcodebuild test-without-building -project OpenRHNTracker.xcodeproj -scheme OpenRHNTracker \
      -destination "id=$id" -derivedDataPath "$DD" -only-testing:OpenRHNTrackerUITests/ScreenshotUITests -quiet || echo "!! $slot $loc mislukt"
    kill $LOCPID 2>/dev/null || true
    xcrun simctl terminate $id $BUNDLE 2>/dev/null || true
  done
done
for f in $OUT/*.png; do
  b=${f:t}; slot=${b%%~*}; rest=${b#*~}; loc=${rest%%~*}; naam=${rest#*~}
  mkdir -p "AppStore/Screenshots/$loc/$slot"; cp "$f" "AppStore/Screenshots/$loc/$slot/$naam"
done
echo "Klaar: $(ls $OUT/*.png | wc -l | tr -d ' ') screenshots"
