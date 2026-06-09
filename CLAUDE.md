# RNH Tracker — Claude instructies

## Projectoverzicht
iOS + WatchOS GPX tracker app voor RHN (Ronde om Noord Holland).
Registreert GPS-sporen op het water, slaat op als GPX, deelt via e-mail/AirDrop.

## Eigenaar
- **Ed Cafferata** (edcafferata@icloud.com) — developer
- **Team ID:** `9J2S23WJH3`

## Locatie & build
- **Project:** `/Volumes/Backup-Ed/AI/RHN-GpxTracker/`
- **Xcode project:** `OpenRHNTracker.xcodeproj`
- **Bundle ID:** `info.cafferata.RnhGpxTracker`
- **GitHub:** https://github.com/EdCafferata/RHN-GpxTracker — branch: `main`
- **Versie:** `2.1.0` (in ontwikkeling, nog niet uitgebracht)
- **Live versie:** `2.0.0` — https://apps.apple.com/nl/app/rhn-tracker/id1598986930
- **Ed's iPhone device ID:** `00008110-000E791A3AD9801E`
- **Simulator ID:** `F6112483-4A4A-457E-8710-B0CAC169B941` (iPhone 16, iOS 18.6)

### Build commando's
```bash
# Device (Ed's iPhone)
cd /Volumes/Backup-Ed/AI/RHN-GpxTracker
xcodebuild -project OpenRHNTracker.xcodeproj -scheme "OpenRHNTracker" \
  -configuration Debug \
  -destination 'id=00008110-000E791A3AD9801E' \
  -derivedDataPath /tmp/rhn-build-device build
xcrun devicectl device install app \
  --device 00008110-000E791A3AD9801E \
  "/tmp/rhn-build-device/Build/Products/Debug-iphoneos/OpenRHNTracker.app"

# Simulator
xcodebuild -project OpenRHNTracker.xcodeproj -scheme "OpenRHNTracker" \
  -destination "platform=iOS Simulator,id=F6112483-4A4A-457E-8710-B0CAC169B941" build

# TestFlight archive
xcodebuild -project OpenRHNTracker.xcodeproj -scheme "OpenRHNTracker" \
  -configuration Release -archivePath /tmp/RHN-GpxTracker.xcarchive archive
# → daarna Xcode Organizer → Distribute App → App Store Connect
```

### Xcode 26.5 workaround (watchOS simulator)
`EXCLUDED_ARCHS[sdk=watchsimulator*]` toegevoegd aan Watch + Watch Extension Release config.
Reden: Xcode 26.5 vereist watchOS 26.5 simulator die nog niet beschikbaar is.

## Sessie start (ALTIJD uitvoeren)
1. `git -C /Volumes/Backup-Ed/AI/RHN-GpxTracker fetch origin && git -C /Volumes/Backup-Ed/AI/RHN-GpxTracker pull origin main`
2. Lees dit bestand + `README.md`
3. Meld wat er nieuw is t.o.v. vorige sessie

## App Store Connect
- **App ID:** `1598986930`
- **Status:** 🟢 Live in App Store (v2.0.0)
- **URL:** https://apps.apple.com/nl/app/rhn-tracker/id1598986930

## Sessie einde (ALTIJD uitvoeren)
1. `git add -A && git commit && git push`
2. Werk `CLAUDE.md` bij
3. Update memory: `/Users/edcafferata/.claude/projects/-Volumes-Backup-Ed-AI-Tattoe-tattoe/memory/project_rhn_tracker.md`

---

## Stack
- **iPhone app:** UIKit, `ViewController.swift`
- **Watch app:** WatchKit, `InterfaceController.swift`
- **Kaartservers:** Apple, OpenStreetMap, OpenSeaMap, CartoDB, CartoDB Dark, OpenTopoMap
- **Tile caching:** MapCache package
- `NSAllowsArbitraryLoads = true` in Info.plist (vereist voor HTTP tile servers)

## Architectuur — ViewController.swift (iPhone)
- `speedReadings: [(date: Date, speedMs: Double)]` — sliding window 60s voor snelheidszoom
- `mapUpdateTimer: Timer?` — vuurt elke 10 seconden
- `startMapUpdateTimer()` / `stopMapUpdateTimer()` / `updateMapRegionForSpeed()`
- `currentGPSProfile: String` — huidig GPS-profiel (log/debug)
- `updateGPSAccuracy(speedMs:)` — past desiredAccuracy + distanceFilter aan op snelheid

### Snelheids-drempelwaarden kaart-zoom
- <0.5kn → 0.002°
- 0.5–2kn → 0.005°
- 2–5kn → 0.010°
- 5–8kn → 0.018°
- ≥8kn → 0.030°
- Zoom past alleen aan als verschil >20% (geen springende kaart)

### GPS-profielen (batterijbesparing)
| Snelheid | desiredAccuracy | distanceFilter |
|---|---|---|
| < 0.5 kn | kCLLocationAccuracyHundredMeters | 50m |
| 0.5–2 kn | kCLLocationAccuracyNearestTenMeters | 10m |
| 2–6 kn | kCLLocationAccuracyBest | 5m |
| > 6 kn | kCLLocationAccuracyBest | 2m |
| Lader-modus | kCLLocationAccuracyBest (altijd) | 2m |

## Reset actieblad (iPhone + Watch)
Volgorde: **Doorgaan** → Opslaan & nieuw → Verwijderen (destructief) → Annuleren
- `CONTINUE_SESSION` sleutel aanwezig in alle 11 taalbestanden

## Talen (11 stuks)
`nl, en, de, es, fr, it, fi-FI, pt-BR, ru, uk, zh-Hans`
Strings in `OpenRHNTracker/<taal>.lproj/Localizable.strings`

## Bestanden
- `CLAUDE.md` — dit bestand, auto-geladen door Claude Code
- `README.md` — publieke beschrijving
- `BOUW_HANDLEIDING.md` — stap-voor-stap bouwhandleiding
- `AANPASSING_TEMPLATE.md` — template voor aanpassingen
- `AppStore/APP_STORE_BESCHRIJVING.md` — App Store tekst NL + EN
- `AppStore/RELEASE_NOTES_v2.1.0.md` — release notes voor volgende versie
- `AppStore/Screenshots/` — 3× iPhone 6.9" + 3× iPad 13" + icon 1024

## Feature status (v2.0.0 — live)
- [x] GPX tracking (iPhone + Watch)
- [x] Kaartservers: Apple, OSM, OpenSeaMap, CartoDB, CartoDB Dark, OpenTopoMap
- [x] Snelheidsgebaseerde kaart-zoom
- [x] "Doorgaan" optie in reset actieblad (iPhone + Watch)
- [x] 11 talen, standaard `.otherNavigation`, scherm altijd aan, OpenSeaMap zoom 18
- [x] EXCLUDED_ARCHS watchOS simulator workaround (Xcode 26.5)
- [x] App-icoon 1024×1024 YSV badge
- [x] App Store screenshots iPhone + iPad
- [x] App Store beschrijving NL + EN

## Nieuw in v2.1.0 (in ontwikkeling, nog niet uitgebracht)
- [x] **Snelheidsgebaseerde GPS-accuraatheid** — 4 profielen, tot 80% batterijbesparing — commit `d35bcf1`
- [x] **'Telefoon op de lader' modus** — Settings → Tracking, altijd best GPS + 2m filter — commit `73415dc`
- [x] About-scherm: BVK → Open RNH Tracker — commit `de114e2`
- [x] README: live badge, correcte App Store URL — commit `1b3b6d4`

## Open issues (backlog)
- [ ] #3 ViewController.swift refactoren (1600+ regels)
