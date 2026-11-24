import XCTest

/// Rooktest: de app moet starten en de kaart met de Start-knop tonen. Vangt precies de klasse
/// fouten die je pas bij een release merkt (zoals de crash zonder scene-levenscyclus, nov 2026).
final class SmokeUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppStartZonderCrash() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20),
                      "App bereikte de voorgrond niet binnen 20 s — waarschijnlijk een crash bij opstarten")
        // De grote groene knop onderaan (Start/Starten, afhankelijk van de taal) bestaat.
        let startKnop = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'Start'")).firstMatch
        XCTAssertTrue(startKnop.waitForExistence(timeout: 20), "Start-knop niet gevonden")
    }
}
