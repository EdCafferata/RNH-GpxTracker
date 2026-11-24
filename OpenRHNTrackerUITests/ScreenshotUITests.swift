import XCTest

/// Maakt App Store-screenshots. Draait alleen als SCREENSHOT_DIR is gezet
/// (xcodebuild ... TEST_RUNNER_SCREENSHOT_DIR=/pad TEST_RUNNER_SCREENSHOT_LANG=nl), anders overgeslagen.
/// Zie AppStore/maak-screenshots.sh — die laat ook een route over het water bij IJmuiden varen.
final class ScreenshotUITests: XCTestCase {
    func testMaakScreenshots() throws {
        let env = ProcessInfo.processInfo.environment
        guard let dir = env["SCREENSHOT_DIR"], let taal = env["SCREENSHOT_LANG"] else {
            throw XCTSkip("Alleen voor het maken van screenshots")
        }
        let prefix = env["SCREENSHOT_PREFIX"] ?? "shot"
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(taal))", "-AppleLocale", taal]
        app.launch()
        XCTAssertTrue(app.buttons["trackerButton"].waitForExistence(timeout: 30))

        // iOS-vraag "ook als je de app niet gebruikt?" (Always-upgrade) wegtikken: tweede knop = "Altijd".
        func sluitSysteemvraag() {
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let vraag = springboard.alerts.firstMatch
            if vraag.waitForExistence(timeout: 3) {
                let knoppen = vraag.buttons
                (knoppen.count > 1 ? knoppen.element(boundBy: 1) : knoppen.firstMatch).tap()
            }
        }

        func bewaar(_ naam: String) throws {
            sluitSysteemvraag()
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(prefix)~\(naam).png")
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
        }

        sluitSysteemvraag()
        sleep(12)                      // weer, wind en waterstand laden
        try bewaar("1-kaart")
        app.buttons["trackerButton"].tap()
        sleep(45)                      // de gesimuleerde route vaart, spoor wordt getekend
        try bewaar("2-opname")
        app.buttons["preferencesButton"].tap()
        sleep(3)
        try bewaar("3-instellingen")
    }
}
