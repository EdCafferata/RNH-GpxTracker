//
//  RadarTileOverlay.swift
//  OpenBVKTracker
//
//  Neerslag radar overlay via Rainviewer API (gratis, geen key).
//

import MapKit

/// Eigen MKTileOverlay subklasse zodat de renderer hem uniek kan herkennen.
class RadarTileOverlay: MKTileOverlay {

    private static let colorScheme = 2   // 0=original, 1=universal blue, 2=TITAN
    private static let smooth      = 1
    private static let snow        = 1

    /// Maak radar overlay aan met een specifiek Rainviewer pad.
    static func make(path: String) -> RadarTileOverlay {
        let template = "https://tilecache.rainviewer.com\(path)/256/{z}/{x}/{y}/\(colorScheme)/\(smooth)_\(snow).png"
        let overlay = RadarTileOverlay(urlTemplate: template)
        overlay.canReplaceMapContent = false
        overlay.minimumZ = 0
        overlay.maximumZ = 22
        overlay.tileSize = CGSize(width: 256, height: 256)
        return overlay
    }
}
