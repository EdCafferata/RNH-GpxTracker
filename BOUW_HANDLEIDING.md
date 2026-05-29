# Bouwhandleiding: iOS GPX Tracker klonen en aanpassen

Dit document beschrijft **alle stappen** die zijn uitgevoerd om de RHN Tracker te maken
op basis van [iOS-Open-GPX-Tracker](https://github.com/merlos/iOS-Open-GPX-Tracker) van Juan M. Merlos.
Volg deze handleiding op een nieuwe Mac om een volledig werkende aangepaste versie te bouwen.

---

## Vereisten

| Tool | Versie | Opmerking |
|------|--------|-----------|
| macOS | 13+ | |
| Xcode | 16+ | Download via App Store |
| Git | meegeleverd | `xcode-select --install` indien nodig |
| Apple ID | gratis | Nodig voor signing op fysiek apparaat |
| Python 3 + Pillow | `pip3 install Pillow` | Alleen voor het genereren van app-iconen |

---

## Stap 1 — Origineel project klonen

```bash
git clone https://github.com/merlos/iOS-Open-GPX-Tracker.git MijnApp-GpxTracker
cd MijnApp-GpxTracker
```

Open het project in Xcode om te controleren dat het compileert:

```bash
open OpenGpxTracker.xcodeproj
```

Selecteer een simulator en druk op ▶ (Cmd+R). De app moet starten zonder fouten.

---

## Stap 2 — Nieuwe Git-repository aanmaken

```bash
git remote remove origin
git remote add origin https://github.com/JOUWGEBRUIKER/JOUWREPO.git
git push -u origin main
```

---

## Stap 3 — Project hernoemen (bestanden en mappen)

Hernoem de volgende mappen in de projectroot:

| Oud | Nieuw |
|-----|-------|
| `OpenGpxTracker/` | `OpenMijnApp/` (of laat staan) |
| `OpenGpxTracker.xcodeproj` | `OpenMijnApp.xcodeproj` |

> **Tip:** Dit is optioneel. De app werkt ook zonder hernoeming.
> Doe het wel als je een volledig schone codebase wilt.

### Hernoeming in Xcode

1. Open het project in Xcode
2. Selecteer het project in de Project Navigator
3. Klik op de target naam en hernoem naar `OpenMijnApp`
4. Klik op `Rename` wanneer Xcode vraagt of gerelateerde bestanden ook hernoemd moeten worden

### CoreData model hernoeming (KRITIEK)

De `.xcdatamodeld` map bevat een inner map. **Beide** moeten overeenkomen:

```
OpenGpxTracker.xcdatamodeld/          ← outer folder
    OpenGpxTracker.xcdatamodel/       ← inner folder (MOET overeenkomen met .xccurrentversion)
        .xccurrentversion
        contents
```

In `.xccurrentversion`:
```xml
<key>_XCCurrentVersionName</key>
<string>OpenMijnApp.xcdatamodel</string>   ← moet exact de inner map naam zijn
```

**Hernoemstap:**
```bash
cd OpenMijnApp   # of de map van je app
mv OpenRHNTracker.xcdatamodeld/OpenGpxTracker.xcdatamodel \
   OpenRHNTracker.xcdatamodeld/OpenMijnApp.xcdatamodel
```

Doe daarna een **clean build** in Xcode: Product → Clean Build Folder (Shift+Cmd+K), dan opnieuw bouwen.

> ⚠️ Als deze namen niet overeenkomen crasht de app bij elke start met:
> `NSFetchRequest could not locate NSEntityDescription for entity name 'CDRoot'`

---

## Stap 4 — Bundle identifier wijzigen

### In `project.pbxproj`

Zoek en vervang alle voorkomens van het oude bundle ID:

| Oud | Nieuw |
|-----|-------|
| `org.merlos.OpenGpxTracker` | `com.mijnbedrijf.MijnApp` |
| `org.merlos.OpenGpxTracker.watchkitapp` | `com.mijnbedrijf.MijnApp.watchkitapp` |
| `org.merlos.OpenGpxTracker.watchkitapp.ext` | `com.mijnbedrijf.MijnApp.watchkitapp.ext` |

> ⚠️ Let op typfouten: de Watch Extension moet exact `[hoofdapp].watchkitapp.ext` zijn,
> anders verschijnt de fout: *"Embedded binary's bundle identifier is not prefixed..."*

### In `OpenMijnApp-Watch Extension/Info.plist`

```xml
<key>WKAppBundleIdentifier</key>
<string>com.mijnbedrijf.MijnApp.watchkitapp</string>
```

### In `OpenMijnApp-Watch/Info.plist`

```xml
<key>WKCompanionAppBundleIdentifier</key>
<string>com.mijnbedrijf.MijnApp</string>
```

---

## Stap 5 — App naam instellen

### Naam op het thuisscherm (`Info.plist`)

```xml
<key>CFBundleDisplayName</key>
<string>Mijn App Naam</string>

<key>CFBundleName</key>
<string>Mijn App Naam</string>
```

### Naam in de titelbalk van de app (`ViewController.swift`)

Zoek de constante `kAppTitle`:

```swift
let kAppTitle: String = "  MIJN APP NAAM"
```

Lettertype en grootte:

```swift
appTitleLabel.font = UIFont.boldSystemFont(ofSize: 14)
```

---

## Stap 6 — App-icoon instellen

Zorg voor een **PNG-afbeelding van minimaal 512×512 px** (bij voorkeur 1024×1024).

Genereer alle iOS-maten met Python:

```python
from PIL import Image

src = "pad/naar/jouw_logo.png"
out_dir = "OpenMijnApp/Images.xcassets/AppIcon.appiconset"

img = Image.open(src).convert("RGBA")
size = 1024

# Maak vierkant canvas met witte achtergrond
canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
scale = int(size * 0.80)
w, h = img.size
ratio = min(scale / w, scale / h)
logo = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)
canvas.paste(logo, ((size - logo.width) // 2, (size - logo.height) // 2), logo)

# Alle benodigde maten
sizes = {
    "Icon.png": 1024, "icon_20pt@2x.png": 40, "icon_20pt@3x.png": 60,
    "icon_29pt@2x.png": 58, "icon_29pt@3x.png": 87,
    "icon_40pt@2x.png": 80, "icon_40pt@3x.png": 120,
    "icon_60pt@2x.png": 120, "icon_60pt@3x.png": 180,
    "icon_20pt.png": 20, "icon_20pt@2x-1.png": 40,
    "icon_29pt.png": 29, "icon_29pt@2x-1.png": 58,
    "icon_40pt.png": 40, "icon_40pt@2x-1.png": 80,
    "icon_76pt.png": 76, "icon_76pt@2x.png": 152, "icon_83.5@2x.png": 167,
}
for filename, px in sizes.items():
    canvas.resize((px, px), Image.LANCZOS).convert("RGB").save(f"{out_dir}/{filename}", "PNG")
```

---

## Stap 7 — Standaard kaartserver instellen

In `Preferences.swift`:

```swift
// Verander van .apple naar gewenste server
private var _tileServer: GPXTileServer = .openSeaMap   // of .openStreetMap, .cartoDB, etc.
```

En de fallback op dezelfde regel eronder:

```swift
tileServerInt = tileServerInt >= GPXTileServer.count ? GPXTileServer.openSeaMap.rawValue : tileServerInt
```

Beschikbare servers (zie `GPXTileServer.swift`):
- `.apple` — Apple Maps
- `.openStreetMap` — OpenStreetMap
- `.openSeaMap` — OpenSeaMap (zeekaart)
- `.cartoDB` — CartoDB
- `.openTopoMap` — Topografische kaart

---

## Stap 8 — Coördinaten-balk aanpassen

In `ViewController.swift`, methode `setupView()`:

```swift
coordsLabel.font = UIFont(name: "DinAlternate-Bold", size: 16.0)
coordsLabel.numberOfLines = 2
coordsLabel.textColor = UIColor.white
coordsLabel.backgroundColor = UIColor(red: 58/255, green: 57/255, blue: 54/255, alpha: 0.80)
```

Constraints (volle breedte, geen marge):

```swift
NSLayoutConstraint(item: coordsLabel, attribute: .leading,
    relatedBy: .equal, toItem: self.view, attribute: .leading,
    multiplier: 1, constant: 0).isActive = true
NSLayoutConstraint(item: coordsLabel, attribute: .trailing,
    relatedBy: .equal, toItem: self.view, attribute: .trailing,
    multiplier: 1, constant: 0).isActive = true
```

Tekst update in `locationManager(_:didUpdateLocations:)`:

```swift
let latFormat = String(format: "%.6f", newLocation.coordinate.latitude)
let lonFormat = String(format: "%.6f", newLocation.coordinate.longitude)
let altitude  = newLocation.altitude.toAltitude(useImperial: useImperial)
let knots     = newLocation.speed >= 0
    ? String(format: "%.1f kn", newLocation.speed * 1.94384) : "·.· kn"
coordsLabel.text = "  Lat  \(latFormat)   Lon  \(lonFormat)\n  Alt  \(altitude)   \(knots)"
```

---

## Stap 9 — Instelbaar opname-interval toevoegen

Dit is een volledig nieuwe functie die niet in het origineel zit.
Vijf bestanden worden aangepast plus twee localisatiebestanden.

### 9a. `Preferences.swift`

**Bij de UserDefaults keys bovenaan:**
```swift
let kDefaultsKeyTrackInterval: String = "TrackIntervalSeconds"
```

**Bij de private variabelen (bij de andere `private var` regels):**
```swift
private var _trackIntervalSeconds: Double = 1.0
```

**In `init()`, na de andere `if let` blokken:**
```swift
if let trackIntervalDouble = defaults.object(forKey: kDefaultsKeyTrackInterval) as? Double {
    _trackIntervalSeconds = max(1.0, trackIntervalDouble)
}
```

**Als nieuwe computed property (bij de andere `var` properties):**
```swift
var trackIntervalSeconds: Double {
    get { return _trackIntervalSeconds }
    set {
        _trackIntervalSeconds = max(1.0, newValue)
        defaults.set(_trackIntervalSeconds, forKey: kDefaultsKeyTrackInterval)
    }
}
```

---

### 9b. `PreferencesTableViewControllerDelegate.swift`

Voeg toe aan het protocol:
```swift
func didUpdateTrackInterval(_ newIntervalSeconds: Double)
```

---

### 9c. `PreferencesTableViewController.swift`

**Stap 1 — Voeg sectieconstanten toe bovenaan het bestand:**
```swift
let kTrackingSection = 7       // na kGPXFilesLocationSection = 6
let kTrackIntervalCell = 0
```

**Stap 2 — Verhoog `numberOfSections` van 7 naar 8:**
```swift
override func numberOfSections(in tableView: UITableView?) -> Int {
    return 8
}
```

**Stap 3 — Voeg toe in `titleForHeaderInSection`:**
```swift
case kTrackingSection: return NSLocalizedString("TRACKING_SECTION", comment: "no comment")
```

**Stap 4 — Voeg toe in `numberOfRowsInSection`:**
```swift
case kTrackingSection: return 1
```

**Stap 5 — Voeg toe in `cellForRowAt`:**
```swift
case kTrackingSection:
    return cellForTrackingSection(at: indexPath)
```

**Stap 6 — Voeg toe in `didSelectRowAt`:**
```swift
if indexPath.section == kTrackingSection {
    showTrackIntervalPicker()
}
```

**Stap 7 — Voeg de twee hulpmethoden toe (bijv. vóór de UIDocumentPickerDelegate sectie):**
```swift
private func cellForTrackingSection(at indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: "TrackingCell")
    cell.textLabel?.text = NSLocalizedString("TRACK_INTERVAL", comment: "no comment")
    cell.detailTextLabel?.text = formatTrackInterval(preferences.trackIntervalSeconds)
    cell.accessoryType = .disclosureIndicator
    return cell
}

private func formatTrackInterval(_ seconds: Double) -> String {
    let s = Int(seconds)
    if s % 3600 == 0 {
        let h = s / 3600
        return h == 1 ? NSLocalizedString("TRACK_INTERVAL_1_HOUR", comment: "no comment")
                      : String(format: NSLocalizedString("TRACK_INTERVAL_HOURS", comment: "no comment"), h)
    } else if s % 60 == 0 {
        let m = s / 60
        return m == 1 ? NSLocalizedString("TRACK_INTERVAL_1_MIN", comment: "no comment")
                      : String(format: NSLocalizedString("TRACK_INTERVAL_MINS", comment: "no comment"), m)
    } else {
        return s == 1 ? NSLocalizedString("TRACK_INTERVAL_1_SEC", comment: "no comment")
                      : String(format: NSLocalizedString("TRACK_INTERVAL_SECS", comment: "no comment"), s)
    }
}

private func showTrackIntervalPicker() {
    let alert = UIAlertController(
        title: NSLocalizedString("TRACK_INTERVAL", comment: "no comment"),
        message: NSLocalizedString("TRACK_INTERVAL_MESSAGE", comment: "no comment"),
        preferredStyle: .alert
    )
    alert.addTextField { tf in
        tf.keyboardType = .numberPad
        tf.placeholder = "1"
        let s = Int(self.preferences.trackIntervalSeconds)
        if s % 3600 == 0 { tf.text = "\(s / 3600)" }
        else if s % 60 == 0 { tf.text = "\(s / 60)" }
        else { tf.text = "\(s)" }
    }
    let applyInterval: (Double) -> Void = { [weak self] seconds in
        guard let self else { return }
        self.preferences.trackIntervalSeconds = seconds
        let ip = IndexPath(row: kTrackIntervalCell, section: kTrackingSection)
        self.tableView.reloadRows(at: [ip], with: .none)
        self.delegate?.didUpdateTrackInterval(seconds)
    }
    alert.addAction(UIAlertAction(title: NSLocalizedString("TRACK_INTERVAL_UNIT_SEC", comment: "no comment"), style: .default) { _ in
        let n = Double(alert.textFields?.first?.text ?? "1") ?? 1
        applyInterval(max(1, n))
    })
    alert.addAction(UIAlertAction(title: NSLocalizedString("TRACK_INTERVAL_UNIT_MIN", comment: "no comment"), style: .default) { _ in
        let n = Double(alert.textFields?.first?.text ?? "1") ?? 1
        applyInterval(max(1, n) * 60)
    })
    alert.addAction(UIAlertAction(title: NSLocalizedString("TRACK_INTERVAL_UNIT_HOUR", comment: "no comment"), style: .default) { _ in
        let n = Double(alert.textFields?.first?.text ?? "1") ?? 1
        applyInterval(max(1, n) * 3600)
    })
    alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel))
    present(alert, animated: true)
}
```

---

### 9d. `ViewController.swift`

**Voeg toe als property (bij de andere `var` properties bovenaan de klasse):**
```swift
var lastTrackedDate: Date?
```

**In de `gpxTrackingStatus` didSet, in het `.tracking` geval, voeg toe als eerste regel:**
```swift
case .tracking:
    lastTrackedDate = nil   // ← voeg deze regel toe
    // ... rest van de bestaande code
```

**Vervang in `locationManager(_:didUpdateLocations:)` de tracking block:**
```swift
// Oud:
if gpxTrackingStatus == .tracking {
    map.addPointToCurrentTrackSegmentAtLocation(newLocation)
    totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
    currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
}

// Nieuw:
if gpxTrackingStatus == .tracking {
    let now = Date()
    let interval = Preferences.shared.trackIntervalSeconds
    if lastTrackedDate == nil || now.timeIntervalSince(lastTrackedDate!) >= interval {
        lastTrackedDate = now
        map.addPointToCurrentTrackSegmentAtLocation(newLocation)
        totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
        currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
    }
}
```

**Voeg delegate methode toe in de `PreferencesTableViewControllerDelegate` extension:**
```swift
func didUpdateTrackInterval(_ newIntervalSeconds: Double) {
    lastTrackedDate = nil
}
```

---

### 9e. Lokalisatiebestanden

Voeg toe aan **`nl.lproj/Localizable.strings`**:
```
"TRACKING_SECTION" = "Opname-interval";
"TRACK_INTERVAL" = "Interval";
"TRACK_INTERVAL_MESSAGE" = "Geef het aantal in en kies de eenheid.";
"TRACK_INTERVAL_UNIT_SEC" = "Seconden";
"TRACK_INTERVAL_UNIT_MIN" = "Minuten";
"TRACK_INTERVAL_UNIT_HOUR" = "Uren";
"TRACK_INTERVAL_1_SEC" = "1 seconde";
"TRACK_INTERVAL_SECS" = "%d seconden";
"TRACK_INTERVAL_1_MIN" = "1 minuut";
"TRACK_INTERVAL_MINS" = "%d minuten";
"TRACK_INTERVAL_1_HOUR" = "1 uur";
"TRACK_INTERVAL_HOURS" = "%d uur";
```

Voeg toe aan **`en.lproj/Localizable.strings`**:
```
"TRACKING_SECTION" = "Recording interval";
"TRACK_INTERVAL" = "Interval";
"TRACK_INTERVAL_MESSAGE" = "Enter the number and choose the unit.";
"TRACK_INTERVAL_UNIT_SEC" = "Seconds";
"TRACK_INTERVAL_UNIT_MIN" = "Minutes";
"TRACK_INTERVAL_UNIT_HOUR" = "Hours";
"TRACK_INTERVAL_1_SEC" = "1 second";
"TRACK_INTERVAL_SECS" = "%d seconds";
"TRACK_INTERVAL_1_MIN" = "1 minute";
"TRACK_INTERVAL_MINS" = "%d minutes";
"TRACK_INTERVAL_1_HOUR" = "1 hour";
"TRACK_INTERVAL_HOURS" = "%d hours";
```

> Herhaal voor elke andere taal die je ondersteunt (de, es, fr, etc.).

---

## Stap 10 — Snelheidsgebaseerde kaart-zoom (automatisch)

Deze functie is al ingebouwd en werkt zonder configuratie. Ze past de zichtbare kaartregio automatisch aan op basis van de gemiddelde vaartsnelheid over de laatste 60 seconden. Hierdoor worden tiles altijd vooruitgeladen, ook bij een lang opname-interval.

### Hoe het werkt

Een aparte timer (elke 10 s) berekent de gemiddelde snelheid onafhankelijk van `trackIntervalSeconds`. Alleen actief wanneer de kaart de gebruiker volgt (`followUser = true`).

| Gemiddelde snelheid | Zichtbaar gebied | Typisch gebruik |
|---------------------|-----------------|----------------|
| < 0,5 kn | 220 m | Ten anker / stilliggend |
| 0,5 – 2 kn | 555 m | Langzaam varen |
| 2 – 5 kn | 1,1 km | Normaal varen |
| 5 – 8 kn | 2,0 km | Snel varen |
| ≥ 8 kn | 3,3 km | Zeer snel |

De zoom wijzigt alleen als het verschil met de huidige regio groter is dan 20% — geen constante springende kaart.

### Drempelwaarden aanpassen

Wil je andere snelheidsdrempels of zoomgebieden? Pas de `switch` in `ViewController.swift` aan in de methode `updateMapRegionForSpeed()`:

```swift
let targetSpan: CLLocationDegrees
switch avgKnots {
case ..<0.5:  targetSpan = 0.002   // anchored  (~220 m)
case 0.5..<2: targetSpan = 0.005   // slow      (~555 m)
case 2..<5:   targetSpan = 0.010   // moderate  (~1.1 km)
case 5..<8:   targetSpan = 0.018   // fast      (~2.0 km)
default:      targetSpan = 0.030   // very fast (~3.3 km)
}
```

`latitudeDelta` van 0.001° ≈ 111 m (ongeacht locatie).

### Timer interval aanpassen

Standaard elke 10 seconden. Aanpassen in `startMapUpdateTimer()`:

```swift
mapUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) ...
//                                                      ^^^^
//                                    verander naar bijv. 5.0 of 30.0
```

### Snelheidshistorie aanpassen

Standaard gemiddelde over de laatste 60 seconden. Aanpassen in `updateMapRegionForSpeed()`:

```swift
speedReadings = speedReadings.filter { now.timeIntervalSince($0.date) <= 60.0 }
//                                                                        ^^^^
//                                             verander naar bijv. 30.0 of 120.0
```

---

## Stap 11 — Over-pagina aanpassen (`about.html`)

```html
<h1>JOUW APP NAAM</h1>
<h4>Aangepast door <a href="https://github.com/JOUWGITHUB">JOUW NAAM</a></h4>
<h4>Gebaseerd op iOS Open GPX Tracker door<br>
    Juan M. Merlos <a href="http://www.twitter.com/merlos">@merlos</a><br>
    &amp; Vincent Neo <a href="https://www.twitter.com/iVincentNeo">@vincentneo</a></h4>
<p>JOUW BESCHRIJVING VAN DE APP</p>
<p>Broncode beschikbaar op <a href="https://github.com/JOUWGITHUB/JOUWREPO">GitHub</a> onder GPL-licentie.</p>
```

---

## Stap 11 — Taal instellen op simulator

```bash
# Permanent Nederlands instellen op de booted simulator
xcrun simctl spawn booted defaults write -g AppleLanguages -array nl
xcrun simctl spawn booted defaults write -g AppleLocale -string nl_NL
# Herstart de simulator daarna
```

---

## Stap 12 — Bouwen en testen

```bash
# Build voor simulator
xcodebuild -scheme OpenMijnApp \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  build

# Installeer op booted simulator
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug-iphonesimulator/OpenMijnApp.app

# Start de app
xcrun simctl launch booted com.mijnbedrijf.MijnApp
```

---

## Stap 13 — Installeren op fysiek apparaat

1. Open het project in Xcode: `open OpenMijnApp.xcodeproj`
2. Sluit je iPhone aan via USB
3. Selecteer je iPhone als doelwit bovenin Xcode
4. Druk op ▶ (Cmd+R)
5. Op je iPhone: **Instellingen → Algemeen → VPN en apparaatbeheer** → vertrouw het certificaat

> Werkt met een gratis Apple ID — geen betaald developer account vereist voor eigen apparaat.

---

## Stap 14 — App Store screenshots genereren

Alle vereiste screenshots worden automatisch gegenereerd vanuit één simulatoropname.

### iPhone screenshots (echte simulator)

```bash
# Zorg dat de booted simulator de app toont, dan:
xcrun simctl io booted screenshot /tmp/simulator_raw.png
```

Gebruik daarna dit Python-script om alle iPhone App Store maten te genereren:

```python
from PIL import Image
import os

src = "/tmp/simulator_raw.png"
out_dir = "AppStore/Screenshots"
os.makedirs(out_dir, exist_ok=True)

screenshot = Image.open(src).convert("RGB")

def fit_screenshot(target_w, target_h):
    canvas = Image.new("RGB", (target_w, target_h), (255, 255, 255))
    ratio = target_h / screenshot.height
    nw = int(screenshot.width * ratio)
    scaled = screenshot.resize((nw, target_h), Image.LANCZOS)
    canvas.paste(scaled, ((target_w - nw) // 2, 0))
    return canvas

iphone_sizes = [
    ("iphone_6.9inch_1320x2868",  1320, 2868),   # iPhone 16 Pro Max — VEREIST
    ("iphone_6.7inch_1290x2796",  1290, 2796),   # iPhone 14/15 Pro Max
    ("iphone_6.5inch_1242x2688",  1242, 2688),   # iPhone 11 Pro Max
    ("iphone_5.5inch_1242x2208",  1242, 2208),   # iPhone 8 Plus
]
for name, w, h in iphone_sizes:
    fit_screenshot(w, h).save(f"{out_dir}/{name}.png", "PNG")
    print(f"  {name}.png")
```

### Watch screenshots (echte Watch simulator)

```bash
# Boot Watch simulators
xcrun simctl boot <UDID_ULTRA>     # bijv. Apple Watch Ultra 3 49mm
xcrun simctl boot <UDID_SERIES>    # bijv. Apple Watch Series 11 46mm
xcrun simctl boot <UDID_SE>        # bijv. Apple Watch SE 40mm

# Installeer Watch app
WATCH_APP="~/Library/Developer/Xcode/DerivedData/.../Debug-watchsimulator/OpenMijnApp-Watch.app"
xcrun simctl install <UDID_ULTRA>  "$WATCH_APP"
xcrun simctl install <UDID_SERIES> "$WATCH_APP"
xcrun simctl install <UDID_SE>     "$WATCH_APP"

# Start de app
xcrun simctl launch <UDID_ULTRA>  com.mijnbedrijf.MijnApp.watchkitapp
xcrun simctl launch <UDID_SERIES> com.mijnbedrijf.MijnApp.watchkitapp
xcrun simctl launch <UDID_SE>     com.mijnbedrijf.MijnApp.watchkitapp

sleep 5

# Screenshots
xcrun simctl io <UDID_ULTRA>  screenshot /tmp/watch_ultra.png
xcrun simctl io <UDID_SERIES> screenshot /tmp/watch_series.png
xcrun simctl io <UDID_SE>     screenshot /tmp/watch_se.png
```

Schaal naar alle App Store Watch maten:

```python
from PIL import Image

sources = {
    "ultra":   "/tmp/watch_ultra.png",
    "series":  "/tmp/watch_series.png",
    "se":      "/tmp/watch_se.png",
}

def fit(img, w, h):
    canvas = Image.new("RGB", (w, h), (0, 0, 0))
    ratio = min(w / img.width, h / img.height)
    nw, nh = int(img.width * ratio), int(img.height * ratio)
    scaled = img.resize((nw, nh), Image.LANCZOS)
    canvas.paste(scaled, ((w - nw) // 2, (h - nh) // 2))
    return canvas

watch_targets = [
    ("watch_49mm_ultra2_410x502.png",    410, 502, "ultra"),
    ("watch_46mm_series10_416x496.png",  416, 496, "series"),
    ("watch_45mm_series9_396x484.png",   396, 484, "series"),
    ("watch_44mm_series6_368x448.png",   368, 448, "series"),
    ("watch_42mm_312x390.png",           312, 390, "se"),
    ("watch_40mm_324x394.png",           324, 394, "se"),
    ("watch_38mm_272x340.png",           272, 340, "se"),
]
for filename, w, h, src_key in watch_targets:
    img = Image.open(sources[src_key]).convert("RGB")
    fit(img, w, h).save(f"AppStore/Screenshots/{filename}", "PNG")
    print(f"  {filename}")
```

### App Store icoon (1024×1024)

```python
from PIL import Image

logo = Image.open("pad/naar/jouw_logo.png").convert("RGBA")
canvas = Image.new("RGB", (1024, 1024), (255, 255, 255))
scale = int(1024 * 0.80)
lw, lh = logo.size
ratio = min(scale / lw, scale / lh)
l = logo.resize((int(lw * ratio), int(lh * ratio)), Image.LANCZOS)
bg = Image.new("RGBA", l.size, (255, 255, 255, 255))
bg.paste(l, (0, 0), l)
canvas.paste(bg.convert("RGB"), ((1024 - l.width) // 2, (1024 - l.height) // 2))
canvas.save("AppStore/Screenshots/appstore_icon_1024x1024.png", "PNG")
```

### Overzicht vereiste App Store formaten

| Platform | Bestand | Afmeting | Vereist? |
|----------|---------|----------|----------|
| iPhone 6.9" | `iphone_6.9inch_1320x2868.png` | 1320×2868 | ✅ Ja |
| iPhone 6.7" | `iphone_6.7inch_1290x2796.png` | 1290×2796 | Aanbevolen |
| iPhone 6.5" | `iphone_6.5inch_1242x2688.png` | 1242×2688 | Optioneel |
| iPhone 5.5" | `iphone_5.5inch_1242x2208.png` | 1242×2208 | Optioneel |
| iPad 13" | `ipad_13inch_2064x2752.png` | 2064×2752 | ✅ Als iPad ondersteund |
| iPad 12.9" | `ipad_12.9inch_2048x2732.png` | 2048×2732 | Optioneel |
| Watch 49mm | `watch_49mm_ultra2_410x502.png` | 410×502 | Als Watch ondersteund |
| Watch 46mm | `watch_46mm_series10_416x496.png` | 416×496 | Als Watch ondersteund |
| Watch 45mm | `watch_45mm_series9_396x484.png` | 396×484 | Optioneel |
| Watch 44mm | `watch_44mm_series6_368x448.png` | 368×448 | Optioneel |
| Watch 42mm | `watch_42mm_312x390.png` | 312×390 | Optioneel |
| Watch 40mm | `watch_40mm_324x394.png` | 324×394 | Optioneel |
| Watch 38mm | `watch_38mm_272x340.png` | 272×340 | Optioneel |
| App Store icoon | `appstore_icon_1024x1024.png` | 1024×1024 | ✅ Ja |

> Alle gegenereerde bestanden voor RHN Tracker staan in `AppStore/Screenshots/`.

---

## Bekende valkuilen

| Probleem | Oorzaak | Oplossing |
|----------|---------|-----------|
| App crasht bij start | CoreData model naamfout | Inner `.xcdatamodel` map naam moet overeenkomen met `.xccurrentversion` |
| "Embedded binary not prefixed" | Watch Extension bundle ID fout | Controleer exact: `[app].watchkitapp.ext` |
| Crash recovery werkt niet | `retrieveFromCoreData()` gebruikt child context | Gebruik `appDelegate.managedObjectContext.execute()` direct |
| Lege taalstrings | Swapped `.lproj` bestanden | Controleer `nl.lproj` vs `en.lproj` inhoud |
| "not stripping binary" warning | watchOS signing voor strip | Harmloze waarschuwing, geen actie nodig |

---

## Bronvermelding

Gebaseerd op [iOS-Open-GPX-Tracker](https://github.com/merlos/iOS-Open-GPX-Tracker)  
door Juan M. Merlos ([@merlos](https://github.com/merlos)) en Vincent Neo ([@vincentneo](https://github.com/vincentneo))  
Licentie: GPL
