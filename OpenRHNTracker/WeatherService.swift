//
//  WeatherService.swift
//  OpenRHNTracker
//
//  Haalt weer- en zeegegevens op (Open-Meteo, Rijkswaterstaat) en zet ze om naar
//  eenvoudige waarden. Geen UI: de ViewController zet de waarden op het scherm.
//  Alle completions komen op de main thread binnen.
//

import Foundation
import CoreLocation

enum WeatherService {

    /// Vaste plek als er (nog) geen GPS-positie is: haven IJmuiden, start/finish van de RNH.
    static let fallback = CLLocationCoordinate2D(latitude: 52.4630, longitude: 4.5480)

    enum DrukTrend { case stijgend, dalend, stabiel, onbekend }

    /// Actuele waarden. `nil` = niet geleverd door de bron (toon dan "—", nooit 0).
    struct Actueel {
        var windKn: Double?
        var windRichting: Double?
        var windstootKn: Double?
        var temperatuur: Double?
        var gevoelsTemperatuur: Double?
        var zichtKm: Double?
        var drukHPa: Double?
        var drukTrend: DrukTrend = .onbekend
        var neerslagMmH: Double?
    }

    // MARK: - Ophalen

    /// Eén Open-Meteo-verzoek voor wind, temperatuur, zicht, luchtdruk (+ 3-uurstrend) en neerslag.
    static func haalActueel(op c: CLLocationCoordinate2D, klaar: @escaping (Actueel?) -> Void) {
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(c.latitude)&longitude=\(c.longitude)"
            + "&current=wind_speed_10m,wind_direction_10m,wind_gusts_10m,temperature_2m,apparent_temperature,"
            + "visibility,surface_pressure,precipitation"
            + "&hourly=surface_pressure&past_hours=3&forecast_hours=1&wind_speed_unit=kn&timezone=Europe%2FAmsterdam")!
        haalJSON(URLRequest(url: url)) { json in klaar(json.flatMap(parseActueel)) }
    }

    /// Golfhoogte in meters (Open-Meteo Marine).
    static func haalGolfhoogte(op c: CLLocationCoordinate2D, klaar: @escaping (Double?) -> Void) {
        let url = URL(string: "https://marine-api.open-meteo.com/v1/marine?latitude=\(c.latitude)&longitude=\(c.longitude)"
            + "&current=wave_height&timezone=Europe%2FAmsterdam")!
        haalJSON(URLRequest(url: url)) { json in
            klaar((json?["current"] as? [String: Any])?["wave_height"] as? Double)
        }
    }

    /// Laatste waterstand bij IJmuiden in cm t.o.v. NAP (Rijkswaterstaat DDAPI).
    static func haalWaterstandIJmuiden(klaar: @escaping (Double?) -> Void) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nu = Date()
        var request = URLRequest(url: URL(string:
            "https://ddapi20-waterwebservices.rijkswaterstaat.nl/ONLINEWAARNEMINGENSERVICES/OphalenWaarnemingen")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("RNHTracker", forHTTPHeaderField: "X-API-KEY")
        let body: [String: Any] = [
            "Locatie": ["Code": "ijmuiden.buitenhaven"],  // "ijmuiden" geeft altijd HTTP 204 (geen data)
            "AquoPlusWaarnemingMetadata": ["AquoMetadata": [
                "Compartiment": ["Code": "OW"],
                "Grootheid": ["Code": "WATHTE"]
            ]],
            "Periode": ["Begindatumtijd": formatter.string(from: nu.addingTimeInterval(-1800)),
                        "Einddatumtijd": formatter.string(from: nu)]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        haalJSON(request) { json in klaar(json.flatMap(parseWaterstand)) }
    }

    /// De DDAPI levert meerdere reeksen (meting, verwachting, astronomisch getij). Neem de laatste
    /// échte meting; is die er niet, dan de verwachting. Nooit blind de eerste reeks.
    static func parseWaterstand(_ json: [String: Any]) -> Double? {
        let reeksen = json["WaarnemingenLijst"] as? [[String: Any]] ?? []
        func laatste(_ procesType: String) -> Double? {
            let reeks = reeksen.first {
                (($0["AquoMetadata"] as? [String: Any])?["ProcesType"] as? String) == procesType
            }
            let metingen = reeks?["MetingenLijst"] as? [[String: Any]]
            return (metingen?.last?["Meetwaarde"] as? [String: Any])?["Waarde_Numeriek"] as? Double
        }
        return laatste("meting") ?? laatste("verwachting")
    }

    // MARK: - Omzetten (los testbaar)

    static func parseActueel(_ json: [String: Any]) -> Actueel? {
        guard let cur = json["current"] as? [String: Any] else { return nil }
        var a = Actueel()
        a.windKn = cur["wind_speed_10m"] as? Double
        a.windRichting = cur["wind_direction_10m"] as? Double
        a.windstootKn = cur["wind_gusts_10m"] as? Double
        a.temperatuur = cur["temperature_2m"] as? Double
        a.gevoelsTemperatuur = cur["apparent_temperature"] as? Double
        a.zichtKm = (cur["visibility"] as? Double).map { $0 / 1000.0 }
        a.drukHPa = cur["surface_pressure"] as? Double
        a.neerslagMmH = cur["precipitation"] as? Double
        if let hourly = json["hourly"] as? [String: Any],
           let drukken = (hourly["surface_pressure"] as? [Any])?.compactMap({ $0 as? Double }),
           drukken.count >= 3, let eerste = drukken.first, let laatste = drukken.last {
            let verschil = laatste - eerste
            a.drukTrend = verschil > 0.5 ? .stijgend : verschil < -0.5 ? .dalend : .stabiel
        }
        return a
    }

    /// Knopen naar Beaufort (WMO-grenzen).
    static func beaufort(knopen: Double) -> Int {
        let grenzen: [Double] = [1, 4, 7, 11, 17, 22, 28, 34, 41, 48, 56, 64]
        return grenzen.firstIndex { knopen < $0 } ?? 12
    }

    /// Pijl in de richting waarheen de wind waait (windrichting = vanwaar hij komt).
    static func windPijl(graden: Double) -> String {
        let pijlen = ["↓", "↙", "←", "↖", "↑", "↗", "→", "↘"]
        let genormaliseerd = (graden.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return pijlen[Int((genormaliseerd + 22.5) / 45.0) % 8]
    }

    // MARK: - Netwerk

    private static func haalJSON(_ request: URLRequest, klaar: @escaping ([String: Any]?) -> Void) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            let json = (error == nil ? data : nil)
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            DispatchQueue.main.async { klaar(json) }
        }.resume()
    }
}
