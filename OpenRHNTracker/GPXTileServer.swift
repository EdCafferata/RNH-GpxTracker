//
//  GPXTileServer.swift
//  OpenRHNTracker
//
//  Created by merlos on 25/01/15.
//
// Shared file: this file is also included in the OpenRHNTracker-Watch Extension target.

import Foundation

///
/// Configuration for supported tile servers.
///
/// Maps displayed in the application are sets of small square images caled tiles. There are different servers that
/// provide these tiles.
///
/// A tile server is defined by an internal id (for instance .openStreetMap), a name string for displaying
/// on the interface and a URL template.
///
enum GPXTileServer: Int {

    /// Apple tile server
    case apple

    /// Apple satellite tile server
    case appleSatellite

    /// OpenStreetMap tile server
    case openStreetMap
    // case AnotherMap

    /// Esri keyless wegenkaart (voorheen CartoDB — Carto heeft z'n gratis keyless
    /// basemaps afgeknepen, okt 2026). Esri World_Street_Map, geen account/key nodig.
    case cartoDB

    /// OpenTopoMap tile server
    case openTopoMap

    /// OpenSeaMap tile server
    case openSeaMap

    // Verwijderd okt 2026 (op verzoek Ed): .cartoDBRetina ("Licht grijs") en
    // .cartoDBDark ("Donker grijs"). De gratis Esri-canvas-lagen hadden alleen echte
    // tegels tot z16 en te weinig beeld boven water; ze bevielen niet. Alleen de
    // Wegenkaart (Esri, .cartoDB) blijft over.

    /// String that describes the selected tile server.
    var name: String {
        switch self {
        case .apple: return "Apple Mapkit (no offline cache)"
        case .appleSatellite: return "Apple Satellite (no offline cache)"
        case .openStreetMap: return "OpenStreetMap"
        case .cartoDB: return "Wegenkaart (Esri)"
        case .openTopoMap: return "OpenTopoMap"
        case .openSeaMap: return "OpenSeaMap"
        }
    }

    /// URL template of current tile server (it is of the form http://{s}.map.tile.server/{z}/{x}/{y}.png
    var templateUrl: String {
        switch self {
        case .apple: return ""
        case .appleSatellite: return ""
        case .openStreetMap: return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        // Esri keyless (geen account/key). Let op: Esri gebruikt {z}/{y}/{x} (y vóór x) en
        // géén subdomeinen. MapCache vervangt de tokens los van volgorde.
        case .cartoDB: return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}"
        case .openTopoMap: return "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png"
        case .openSeaMap: return "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png"
        }
    }

    /// In the `templateUrl` the {s} means subdomain, typically the subdomains available are a,b and c
    /// Check the subdomains available for your server.
    ///
    /// Set an empty array (`[]`) in case you don't use `{s}` in your `templateUrl`.
    ///
    /// Subdomains is useful to distribute the tile request download among the diferent servers
    /// and displaying them faster as result.
    var subdomains: [String] {
        switch self {
        case .apple: return []
        case .appleSatellite: return []
        case .openStreetMap: return ["a", "b", "c"]
        case .cartoDB: return []
        case .openTopoMap: return ["a", "b", "c"]
        case .openSeaMap: return []
        }
    }

    /// Maximum zoom level the tile server supports
    /// Tile servers provide files till a certain level of zoom that ranges from 0 to maximumZ.
    /// If map zooms more than the limit level, tiles won't be requested.
    ///
    ///  Typically the value is around 19,20 or 21.
    ///
    ///  Use negative to avoid setting a limit.
    ///
    /// - see https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Tile_servers
    ///
    var maximumZ: Int {
        switch self {
        case .apple:
            return -1
        case .appleSatellite:
            return -1
        case .openStreetMap:
            return 19
        case .cartoDB:
            return 19
        case .openTopoMap:
            return 17
        // case .AnotherMap: return 10
        case .openSeaMap:
            return 18
        }
    }
    ///
    /// Minimum zoom supported by the tile server
    ///
    /// This limits the tiles requested based on current zoom level.
    /// No tiles will be requested for zooms levels lower that this.
    ///
    /// Needs to be 0 or larger.
    ///
    var minimumZ: Int {
        switch self {
        case .apple:
            return 0
        case .appleSatellite:
            return 0
        case .openStreetMap:
            return 0
        case .cartoDB:
            return 0
        case .openTopoMap:
            return 0
        case .openSeaMap:
            return 0
        }
    }

    /// Does the tile overlay replace the map?
    ///  Generally all the tiles provided replace the AppleMaps. However there are some
    var canReplaceMapContent: Bool {
        switch self {
        case .openSeaMap: return false
        default: return true
        }
    }

    /// tile size of the third-party tile.
    ///
    /// 1x tiles are 256x256
    var tileSize: Int {
        return 256
    }

    /// Defines the color mode for the tile server
    enum GPXTileServerColorMode {
        case lightMode
        case system
        case darkMode
    }

    /// Returns the color mode for the tile server
    var colorMode: GPXTileServerColorMode {
        switch self {
        case .apple: return .system
        case .appleSatellite: return .darkMode
        case .cartoDB, .openTopoMap, .openSeaMap, .openStreetMap: return .lightMode
        }
    }

    /// Returns the number of tile servers currently defined
    static var count: Int { return GPXTileServer.openSeaMap.rawValue + 1}
}
