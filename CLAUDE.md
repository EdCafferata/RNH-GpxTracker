# RHN Tracker — Claude instructies

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
- **Versie:** `2.0.0` (build 1)
- **Simulator ID:** `F6112483-4A4A-457E-8710-B0CAC169B941` (iPhone 16, iOS 18.6)

### Build commando's
```bash
# Simulator
cd /Volumes/Backup-Ed/AI/RHN-GpxTracker
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
- **Status:** Verwijderd wegens guideline 4.0.0 (niet bijgewerkt sinds 2021)
- **Actie:** Versie 2.0.0 build uploaden via TestFlight → App Store Connect → App beschikbaar stellen

## Sessie einde (ALTIJD uitvoeren)
1. `git add -A && git commit && git push`
2. Werk `CLAUDE.md` bij
3. Update memory: `/Users/edcafferata/.claude/projects/-Volumes-Backup-Ed-AI-Tattoe-tattoe/memory/project_rhn_tracker.md`

---

## Stack
- **iPhone app:** UIKit, `ViewController.swift` (1500+ regels)
- **Watch app:** WatchKit, `InterfaceController.swift`
- **Kaartservers:** Apple, OpenStreetMap, OpenSeaMap, CartoDB, OpenTopoMap
- **Tile caching:** MapCache package
- `NSAllowsArbitraryLoads = true` in Info.plist (vereist voor HTTP tile servers)

## Architectuur — ViewController.swift (iPhone)
- `speedReadings: [(date: Date, speedMs: Double)]` — sliding window 60s voor snelheidszoom
- `mapUpdateTimer: Timer?` — vuurt elke 10 seconden
- `startMapUpdateTimer()` / `stopMapUpdateTimer()` / `updateMapRegionForSpeed()`
- Snelheids-drempelwaarden kaart-zoom:
  - <0.5kn → 0.002°
  - 0.5-2kn → 0.005°
  - 2-5kn → 0.010°
  - 5-8kn → 0.018°
  - ≥8kn → 0.030°
  - Zoom past alleen aan als verschil >20% (geen springende kaart)

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

## Feature status
- [x] GPX tracking (iPhone + Watch)
- [x] Kaartservers: Apple, OSM, OpenSeaMap, CartoDB, CartoDB Dark Matter, OpenTopoMap
- [x] Snelheidsgebaseerde kaart-zoom (losgekoppeld van opname-interval)
- [x] Snelheids-zoom stopt bij pauze/reset, herstart bij recording
- [x] "Doorgaan" optie in reset actieblad (iPhone + Watch)
- [x] 11 talen
- [x] Standaard activiteitstype `.otherNavigation`
- [x] Scherm altijd aan standaard ingeschakeld
- [x] OpenSeaMap max zoom 18
- [x] EXCLUDED_ARCHS watchOS simulator workaround (Xcode 26.5)
- [x] **App-icoon:** 1024×1024 YSV Ronde om Noord-Holland badge — issue #4 gesloten (2026-05-29)
- [x] **Build 2.0.0 geüpload naar App Store Connect** — Delivery UUID: 9dc4e291-f9e9-4709-aaec-605c5e9e521c (2026-05-29)
- [ ] **In App Store Connect:** screenshots toevoegen + versie indienen voor review

## Open issues (backlog)
- [ ] #1 App Store beschrijving uitbreiden met volledige functielijst
- [ ] #2 Batterijverbruik optimaliseren: GPS accuraatheid aanpassen op snelheid
- [ ] #3 ViewController.swift refactoren (1647+ regels)
- [ ] #5 App Store Connect: minimaal 3 screenshots toevoegen
- [ ] #6 App beschikbaar stellen in alle landen (taalbestanden aanwezig)
