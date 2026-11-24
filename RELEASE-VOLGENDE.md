# RNH Tracker — volgende versie: niet vergeten (naar BVK-voorbeeld, 24 nov 2026)

Stand: 2.2.1 live (min iOS 15) — **start niet op de nieuwste iOS** (geen UIScene). 2.3.0 lost dat op.

- [x] **Scene-levenscyclus** (SceneDelegate) — anders crasht de app bij opstarten op de nieuwste iOS.
- [x] **Privacy/support/marketing-URL's** naar `cafferata.info/rnh-tracker/…` (NL) en `/rnh-tracker/en/…` (EN),
      in `fastlane/metadata/{nl-NL,en-US}/*_url.txt`. Live versie kon niet via de API (409): gaat mee met 2.3.0.
- [x] **Zoekwoorden** opgeschoond (geen `;`/`Cafferata` meer, 100 tekens, NL + EN).
- [x] **Versie in Info.plists** = `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` (stond hard op 2.2.1 → upload geweigerd).
- [x] **Screenshots** NL + EN: iPhone 6,9", iPad 13", iPhone Duo — `AppStore/maak-screenshots.sh`.
- [ ] Ed test 2.3.0 op zijn iPhone (opstarten, opnemen, opslaan met "/", waterstand, Watch-route).
- [ ] Pre-release-check (skill `pre-release-app-review`) vóór indienen.
- [ ] Na livegang: README/CLAUDE.md "live versie" bijwerken.
