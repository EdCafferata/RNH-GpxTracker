# Aanpassingstemplate — iOS GPX Tracker

Vul dit bestand in voordat je begint. Alle antwoorden worden gebruikt in de bouwstappen
beschreven in `BOUW_HANDLEIDING.md`. Bewaar dit bestand in je eigen repository.

---

## 1. Organisatie / Club

```
Naam organisatie      : [bijv. WSV Ronde om Noord Holland]
Afkorting             : [bijv. RHN]
Website               : [bijv. https://www.blocq.nl]
Contactpersoon        : [naam van de bouwaanvrager]
E-mail contactpersoon : [e-mailadres]
```

---

## 2. App naam en identiteit

```
App naam (thuisscherm)  : [max. ~12 tekens, bijv. RHN Tracker]
App naam (in titelbalk) : [bijv. RHN GPX TRACKER]
Lettergrootte titelbalk : [bijv. 14pt]
Versienummer            : [bijv. 1.0.0]
```

---

## 3. Bundle identifier

```
Bundle ID hoofdapp      : [bijv. com.mijnclub.MijnApp]
Bundle ID Watch app     : [zelfde + .watchkitapp,  bijv. com.mijnclub.MijnApp.watchkitapp]
Bundle ID Watch ext.    : [zelfde + .watchkitapp.ext]
Apple Developer Team ID : [te vinden in developer.apple.com → Account, bijv. AB12CD34EF]
```

> Het bundle ID is de unieke naam van jouw app in het Apple ecosysteem.
> Gebruik de omgekeerde domeinnaam van je organisatie als je die hebt.
> Anders: `com.JOUWVOORNAAM.APPNAAM`

---

## 4. GitHub repository

```
GitHub gebruikersnaam : [bijv. EdCafferata]
Repository naam       : [bijv. RHN-GpxTracker]
Volledige URL         : [bijv. https://github.com/EdCafferata/RHN-GpxTracker]
```

---

## 5. App-icoon

```
Logo bestandsnaam     : [bijv. bvk_logo.png]
Logo locatie          : [pad op je computer of URL, bijv. https://www.mijnclub.nl/images/logo.png]
Logo resolutie        : [bijv. 1024x1024 px — minimaal 512x512 aanbevolen]
Achtergrondkleur      : [kleur achter het logo in het icoon, bijv. wit (#FFFFFF) of transparant]
```

> Het Python-script in BOUW_HANDLEIDING.md stap 6 genereert alle iOS-maten automatisch.
> Bij een lage resolutie (< 200px) wordt het icoon wazig — vraag dan een hogere resolutie op.

---

## 6. Kleurenschema

```
Achtergrondkleur titelbalk  : [standaard: donkergrijs RGB(58,57,54) met 80% dekking]
Tekstkleur titelbalk        : [standaard: wit]
Achtergrondkleur coörd.balk : [standaard: zelfde als titelbalk]
Accentkleur knoppen         : [standaard: groen=start, paars=pauze, rood=reset, blauw=opslaan]
```

> Laat velden leeg om de standaardkleuren te gebruiken.

---

## 7. Standaard kaartserver

```
Standaard kaart : [kies één: Apple / OpenStreetMap / OpenSeaMap / CartoDB / OpenTopoMap]
```

> OpenSeaMap = zeekaart (aanbevolen voor watersport)
> OpenStreetMap = wegkaart voor wandelen/fietsen
> Apple Maps = standaard iOS kaart

---

## 8. Coördinaten-balk inhoud

```
Rij 1 inhoud : [standaard: Lat + Lon]
Rij 2 inhoud : [standaard: Altitude + Snelheid in knoten]
Snelheidseenheid : [kn (knoten) / km/u / mph]
```

---

## 9. Standaard opname-interval

```
Standaard interval : [bijv. 1 seconde — minimum is 1 seconde]
```

> Kan door de gebruiker later aangepast worden in de Voorkeuren-pagina.

---

## 9b. Snelheidsgebaseerde kaart-zoom

```
Gebruik standaard drempelwaarden? : [Ja / Nee]

Indien Nee — geef gewenste waarden op:
  Timer interval (seconden)        : [standaard: 10]
  Snelheidshistorie (seconden)     : [standaard: 60]

  Drempelwaarden (knoten → latitudeDelta):
    Stilliggend  (< X kn) → span : [standaard: < 0.5 kn → 0.002°]
    Langzaam     (X–Y kn) → span : [standaard: 0.5–2 kn → 0.005°]
    Normaal      (X–Y kn) → span : [standaard: 2–5 kn   → 0.010°]
    Snel         (X–Y kn) → span : [standaard: 5–8 kn   → 0.018°]
    Zeer snel    (> X kn) → span : [standaard: ≥ 8 kn   → 0.030°]
```

> 0.001° latitudeDelta ≈ 111 m. Zie BOUW_HANDLEIDING.md stap 10 voor instructies.
> De zoom past alleen aan als het verschil > 20% is — geen springende kaart.

---

## 10. Taal

```
Primaire taal app : [bijv. Nederlands (nl) / Engels (en) / Duits (de)]
```

> De app ondersteunt ook: de, es, fr, it, fi, pt-BR, ru, uk, zh-Hans.
> Strings voor nieuwe functies moet je zelf toevoegen in het `.lproj` bestand van jouw taal.

---

## 11. Over-pagina tekst

```
Titel over-pagina      : [bijv. RHN GPX Tracker]
Gemaakt door (naam)    : [bijv. Ed Cafferata]
GitHub profiel URL     : [bijv. https://github.com/EdCafferata]
Beschrijving van de app: [2-3 zinnen over wat de app doet en voor wie]

Voorbeeld:
  "RHN GPX Tracker is een gratis GPS-trackingapp voor zeilers en iedereen
   die onderweg nauwkeurige GPX-sporen wil vastleggen. Vrij te gebruiken en te delen."
```

---

## 12. Activiteitstype (standaard)

```
Standaard activiteitstype : [kies één]
  - Automatisch           (system kiest zelf — algemeen gebruik)
  - Automotive            (auto, voertuig)
  - Fitness               (wandelen, hardlopen, fietsen)
  - Andere navigatie      (boot, trein — aanbevolen voor watersport)
  - Vliegen               (vliegtuig, drone)
```

---

## 13. Datum/bestandsnaam formaat

```
Bestandsnaam formaat : [standaard: dd-MMM-yyyy-HHmm, bijv. 19-May-2026-1430]
Tijdzone             : [Lokaal / UTC]
```

---

## 14. App Store screenshots

```
Taal screenshots        : [bijv. Nederlands]
Achtergrondkleur iPhone : [standaard: wit — of bijv. lichtgrijs #F5F5F5]
Achtergrondkleur Watch  : [standaard: zwart]
Achtergrondkleur iPad   : [standaard: lichtgrijs]

Wil je een tekstbanner boven/onder de screenshots?
  Ja / Nee              : [Nee]
  Tekst banner          : [bijv. "GPS tracking voor zeilers"]
```

> Zie `BOUW_HANDLEIDING.md` stap 14 voor het Python-script dat alle
> 14 App Store formaten automatisch genereert vanuit één simulatoropname.
> Alle gegenereerde bestanden voor RHN GPX Tracker staan in `AppStore/Screenshots/`.

---

## 15. Simulator voor testen

```
Simulator naam  : [bijv. iPhone 17]
iOS versie      : [bijv. 26 (nieuwste)]
Watch simulator : [bijv. Apple Watch Series 11 46mm]
Simulator taal  : [bijv. nl voor Nederlands]
```

---

## Checklist na invullen

Ga door naar `BOUW_HANDLEIDING.md` en verwerk bovenstaande antwoorden stap voor stap:

- [ ] Stap 1 — Project gekloned
- [ ] Stap 2 — Eigen Git repository aangemaakt
- [ ] Stap 3 — Bestanden hernoemd (optioneel)
- [ ] Stap 4 — Bundle identifiers ingesteld (sectie 3 van dit template)
- [ ] Stap 5 — App naam ingesteld (sectie 2)
- [ ] Stap 6 — App-icoon gegenereerd (sectie 5)
- [ ] Stap 7 — Standaard kaartserver ingesteld (sectie 7)
- [ ] Stap 8 — Coördinaten-balk aangepast (sectie 8)
- [ ] Stap 9 — Opname-interval ingesteld (sectie 9)
- [ ] Stap 10 — Kaart-zoom drempelwaarden aangepast indien gewenst (sectie 9b)
- [ ] Stap 11 — Over-pagina aangepast (sectie 11)
- [ ] Stap 11 — Simulator taal ingesteld (sectie 15)
- [ ] Stap 12 — Gebouwd en getest op simulator
- [ ] Stap 13 — Getest op fysiek apparaat
- [ ] Stap 14 — App Store screenshots gegenereerd (sectie 14)
- [ ] Commit & push naar eigen repository
