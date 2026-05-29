# RHN Tracker 🚤

[![Available on the App Store](https://merlos.github.io/iOS-Open-RHN-Tracker/images/download-app-store.svg)](https://apps.apple.com/nl/app/bvk-gpx-tracker/id1598986930)
![Versie](https://img.shields.io/badge/versie-2.0.0-blue)
![Platform](https://img.shields.io/badge/platform-iOS%2012%2B%20%7C%20watchOS-lightgrey)

GPS tracker voor iPhone en Apple Watch. Speciaal gebouwd voor **RHN — Ronde om Noord Holland**. Registreer je vaarroute, voeg waypoints toe en deel je GPX-sporen via e-mail of AirDrop.

---

## Wat is nieuw in versie 2.0.0

- 🗺️ **Snelheidsgebaseerde kaart-zoom** — de kaart zoomt automatisch mee met je vaartsnelheid
- ↩️ **"Doorgaan" optie** in het reset-actieblad — sessie hervatten zonder opslaan
- 🍎 **Apple Watch** — zelfde "Doorgaan" optie beschikbaar op de Watch

---

## Functies

### iPhone
- GPS-spoor opnemen en weergeven op de kaart
- Kaartservers: Apple Maps, OpenStreetMap, OpenSeaMap, CartoDB, OpenTopoMap
- Offline kaartcache (browse het gebied vooraf)
- Pauze / Hervat opname
- Waypoints toevoegen (op locatie of via lang indrukken op kaart)
- Waypoint naam bewerken, verplaatsen, verwijderen
- Bestaande sessie laden en verder opnemen
- Huidige locatie, hoogte, snelheid, koers en nauwkeurigheid
- Opgenomen afstand (totaal + huidig segment)
- GPX-bestanden importeren vanuit andere apps
- GPX-bestanden delen via e-mail / AirDrop / andere apps
- Bestandsoverdracht via iTunes
- Donkere modus
- **Snelheidsgebaseerde kaart-zoom** (automatisch, 5 niveaus)

### Apple Watch
- GPX-sporen opnemen op de Watch
- Pauze / Hervat
- Opslaan als GPX-bestand
- Waypoint toevoegen op huidige locatie
- Bestand sturen naar gekoppelde iPhone
- GPS-signaalsterkte weergeven
- Locatie-informatie: snelheid, lat/lon, hoogte
- **"Doorgaan"** optie in reset-actieblad

### Talen (11)
Nederlands, Engels, Duits, Spaans, Frans, Italiaans, Fins, Portugees (Brazilië), Russisch, Oekraïens, Chinees (vereenvoudigd)

---

## Versiegeschiedenis

| Versie | Datum | Wijzigingen |
|--------|-------|-------------|
| **2.0.0** | 2026-05-29 | Snelheidsgebaseerde zoom, "Doorgaan" actieblad iPhone + Watch, live in App Store |
| 1.10.1 | 2026-05-22 | TestFlight release, stabiliteitsverbeteringen |

---

## Installeren

De app is beschikbaar in de **[App Store](https://apps.apple.com/nl/app/bvk-gpx-tracker/id1598986930)**.

Je kunt de broncode ook zelf compileren met Xcode:
```bash
git clone https://github.com/EdCafferata/RHN-GpxTracker.git
open OpenRHNTracker.xcodeproj
```

---

## Technische details

- **Platform:** iOS 12+ / watchOS
- **Taal:** Swift / UIKit / WatchKit
- **Kaartcaching:** MapCache package
- **Privacy:** alle GPS-data blijft op het apparaat of in iCloud als je het daar zelf plaatst — niets wordt gedeeld met derden

---

## Eigenaren

| Naam | Rol |
|------|-----|
| Ed Cafferata | Ontwikkelaar |
| RHN — Ronde om Noord Holland | Opdrachtgever |

---

## Licentie

Open RHN Tracker — gebaseerd op [Open GPX Tracker](https://github.com/merlos/iOS-Open-GPX-Tracker) door Juan M. Merlos.
Uitgebracht onder de **GNU General Public License v3.0**.

Gebruikt:
- [CoreGPX Framework](https://github.com/vincentneo/CoreGPX) door [@vincentneo](https://github.com/vincentneo)
