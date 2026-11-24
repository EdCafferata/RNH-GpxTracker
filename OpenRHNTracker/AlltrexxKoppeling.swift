//
//  AlltrexxKoppeling.swift
//  OpenRHNTracker
//
//  Optioneel live meevaren op alltrexx.live (Voorkeuren → Alltrexx.live).
//  Zelfde backend-protocol als de Alltrexx Mobile-app:
//    POST /api/sleutel/gratis   {naam, type: "BOAT", bron: "rnh"}  → {id, naam, type, token}
//    POST /api/mobiel/positie   {token, lat, lon, snelheid, koers, hoogte}
//  Er wordt alleen iets verstuurd als de gebruiker het zelf aanzet.
//

import Foundation
import CoreLocation

enum AlltrexxKoppeling {

    static let basisURL = URL(string: "https://alltrexx.live")!
    /// Minimaal interval tussen twee posities (batterij en data op zee).
    static let interval: TimeInterval = 15

    private static let tokenKey = "alltrexx-token"
    private static let trackerIdKey = "alltrexx-tracker-id"
    private static let naamKey = "alltrexx-naam"
    private static let actiefKey = "alltrexx-actief"
    private static var laatsteVerzonden: Date?

    static var token: String? { UserDefaults.standard.string(forKey: tokenKey) }
    static var naam: String? { UserDefaults.standard.string(forKey: naamKey) }
    static var isGekoppeld: Bool { token != nil }

    /// Of live delen aan staat (alleen mogelijk met een sleutel).
    static var actief: Bool {
        get { isGekoppeld && UserDefaults.standard.bool(forKey: actiefKey) }
        set { UserDefaults.standard.set(newValue, forKey: actiefKey) }
    }

    /// Live kaart met de zeekaart-preset en alleen boten.
    static var liveKaartURL: URL { URL(string: "https://alltrexx.live/?laag=boot&types=BOAT")! }

    enum Fout: LocalizedError {
        case teVaak, naamGeweigerd, server(Int), onverwacht
        var errorDescription: String? {
            switch self {
            case .teVaak: return NSLocalizedString("ALLTREXX_ERROR_RATE", comment: "")
            case .naamGeweigerd: return NSLocalizedString("ALLTREXX_ERROR_NAME", comment: "")
            case .server, .onverwacht: return NSLocalizedString("ALLTREXX_ERROR_SERVER", comment: "")
            }
        }
    }

    /// Vraagt een gratis sleutel aan voor deze boot en zet live delen aan.
    static func koppel(naam: String, klaar: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: basisURL.appendingPathComponent("/api/sleutel/gratis"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // "bron" laat alltrexx.live RNH-boten herkennen (RNH-knop, alltrexx_live-issue); onbekende velden negeert de server.
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["naam": naam, "type": "BOAT", "bron": "rnh"])
        URLSession.shared.dataTask(with: request) { data, response, error in
            let resultaat: Result<Void, Error>
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let error = error {
                resultaat = .failure(error)
            } else if status == 429 {
                resultaat = .failure(Fout.teVaak)
            } else if status == 400 {
                resultaat = .failure(Fout.naamGeweigerd)
            } else if !(200...299).contains(status) {
                resultaat = .failure(Fout.server(status))
            } else if let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let token = json["token"] as? String {
                let defaults = UserDefaults.standard
                defaults.set(token, forKey: tokenKey)
                defaults.set(json["id"] as? Int ?? 0, forKey: trackerIdKey)
                defaults.set(json["naam"] as? String ?? naam, forKey: naamKey)
                defaults.set(true, forKey: actiefKey)
                resultaat = .success(())
            } else {
                resultaat = .failure(Fout.onverwacht)
            }
            DispatchQueue.main.async { klaar(resultaat) }
        }.resume()
    }

    /// Ontkoppelt dit toestel: wist de sleutel lokaal (de tracker verloopt vanzelf op de server).
    static func ontkoppel() {
        [tokenKey, trackerIdKey, naamKey, actiefKey].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    /// Door de ViewController bij elke GPS-update aangeroepen; verstuurt hooguit elke `interval` seconden.
    static func nieuwePositie(_ locatie: CLLocation) {
        guard actief, let token = token else { return }
        if let laatste = laatsteVerzonden, Date().timeIntervalSince(laatste) < interval { return }
        laatsteVerzonden = Date()
        var body: [String: Any] = ["token": token,
                                   "lat": locatie.coordinate.latitude,
                                   "lon": locatie.coordinate.longitude]
        if locatie.speed >= 0 { body["snelheid"] = locatie.speed }
        if locatie.course >= 0 { body["koers"] = locatie.course }
        if locatie.verticalAccuracy >= 0 { body["hoogte"] = locatie.altitude }
        var request = URLRequest(url: basisURL.appendingPathComponent("/api/mobiel/positie"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            // 403 = sleutel verlopen/onbekend → live delen uitzetten, gebruiker kan opnieuw koppelen.
            if (response as? HTTPURLResponse)?.statusCode == 403 {
                DispatchQueue.main.async { ontkoppel() }
            }
        }.resume()
    }
}
