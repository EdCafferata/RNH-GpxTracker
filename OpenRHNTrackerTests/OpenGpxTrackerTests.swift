//
//  OpenGpxTrackerTests.swift
//  OpenRHNTrackerTests
//
//  Tests voor het riskante deel: opslaan van routes (geen stil dataverlies) en de
//  omrekeningen in de infobalk.
//

import XCTest
import CoreLocation
@testable import OpenRHNTracker

final class GPXFileManagerTests: XCTestCase {
    private let gpx = "<?xml version=\"1.0\"?><gpx version=\"1.1\"></gpx>"
    private var aangemaakt: [String] = []

    override func tearDown() {
        aangemaakt.forEach { GPXFileManager.removeFile($0) }
        super.tearDown()
    }

    private func uniekeNaam(_ prefix: String) -> String {
        let naam = "\(prefix)-\(UUID().uuidString.prefix(8))"
        aangemaakt.append(naam)
        return naam
    }

    /// Een "/" in de naam liet het opslaan vroeger stil mislukken (niet-bestaande submap),
    /// waarna de herstelkopie werd gewist en de route weg was.
    func testNaamMetSlashWordtGewoonOpgeslagen() {
        let naam = uniekeNaam("RNH 2026/1")
        XCTAssertTrue(GPXFileManager.save(naam, gpxContents: gpx))
        XCTAssertTrue(GPXFileManager.fileExists(naam))
        aangemaakt.append(GPXFileManager.sanitizedFilename(naam))
    }

    func testMislukteOpslagMeldtFalse() {
        let onmogelijk = URL(fileURLWithPath: "/bestaat/niet/route.gpx")
        XCTAssertFalse(GPXFileManager.saveToURL(onmogelijk, gpxContents: gpx))
    }

    func testOpschonenVanBestandsnaam() {
        XCTAssertEqual(GPXFileManager.sanitizedFilename("a/b:c"), "a-b-c")
        XCTAssertEqual(GPXFileManager.sanitizedFilename("   "), "track")
    }

    /// Een route van de Watch met een bestaande naam mag niet stil verdwijnen.
    func testWatchBestandMetBestaandeNaamKrijgtVolgnummer() throws {
        let naam = uniekeNaam("watch")
        XCTAssertTrue(GPXFileManager.save(naam, gpxContents: gpx))
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).gpx")
        try gpx.write(to: tmp, atomically: true, encoding: .utf8)

        let opgeslagen = GPXFileManager.moveFrom(tmp, fileName: "\(naam).gpx")

        XCTAssertEqual(opgeslagen, "\(naam) (2).gpx")
        aangemaakt.append("\(naam) (2)")
        XCTAssertTrue(GPXFileManager.fileExists("\(naam) (2)"))
    }
}

final class WeatherServiceTests: XCTestCase {
    func testBeaufortGrenzen() {
        XCTAssertEqual(WeatherService.beaufort(knopen: 0), 0)
        XCTAssertEqual(WeatherService.beaufort(knopen: 0.9), 0)
        XCTAssertEqual(WeatherService.beaufort(knopen: 1), 1)
        XCTAssertEqual(WeatherService.beaufort(knopen: 16.9), 4)
        XCTAssertEqual(WeatherService.beaufort(knopen: 17), 5)
        XCTAssertEqual(WeatherService.beaufort(knopen: 63.9), 11)
        XCTAssertEqual(WeatherService.beaufort(knopen: 64), 12)
    }

    func testWindPijl() {
        XCTAssertEqual(WeatherService.windPijl(graden: 0), "↓")    // noordenwind waait naar het zuiden
        XCTAssertEqual(WeatherService.windPijl(graden: 270), "→")  // westenwind waait naar het oosten
        XCTAssertEqual(WeatherService.windPijl(graden: 360), "↓")
        XCTAssertEqual(WeatherService.windPijl(graden: -90), "→")
    }

    /// Ontbrekende waarden moeten nil blijven (scherm toont "—"), niet 0 ("0.0 km zicht").
    func testOntbrekendeWaardenBlijvenNil() {
        let json: [String: Any] = ["current": ["temperature_2m": 12.5]]
        let a = WeatherService.parseActueel(json)
        XCTAssertEqual(a?.temperatuur, 12.5)
        XCTAssertNil(a?.zichtKm)
        XCTAssertNil(a?.drukHPa)
        XCTAssertEqual(a?.drukTrend, .onbekend)
    }

    func testDrukTrend() {
        let json: [String: Any] = ["current": ["surface_pressure": 1010.0],
                                   "hourly": ["surface_pressure": [1008.0, 1009.0, 1010.0, 1011.0]]]
        XCTAssertEqual(WeatherService.parseActueel(json)?.drukTrend, .stijgend)
        XCTAssertEqual(WeatherService.parseActueel(json)?.zichtKm, nil)
    }

    func testWaterstandKiestDeMeting() {
        func reeks(_ type: String, _ waarde: Double) -> [String: Any] {
            ["AquoMetadata": ["ProcesType": type], "MetingenLijst": [["Meetwaarde": ["Waarde_Numeriek": waarde]]]]
        }
        let json: [String: Any] = ["WaarnemingenLijst": [reeks("astronomisch", -80), reeks("meting", -66), reeks("verwachting", -60)]]
        XCTAssertEqual(WeatherService.parseWaterstand(json), -66)
        XCTAssertEqual(WeatherService.parseWaterstand(["WaarnemingenLijst": [reeks("verwachting", -60)]]), -60)
        XCTAssertNil(WeatherService.parseWaterstand([:]))
    }
}
