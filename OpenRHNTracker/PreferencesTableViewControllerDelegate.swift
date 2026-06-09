//
//  PreferencesTableViewControllerDelegate.swift
//  OpenRHNTracker
//
//  Created by merlos on 24/10/15.
//

import Foundation

///
/// Delegate protocol of the view controller that displays the list of tile servers
///
///
protocol PreferencesTableViewControllerDelegate: AnyObject {
    
    /// User updated tile server
    func didUpdateTileServer(_ newGpxTileServer: Int)
    
    /// User updated the usage of the caché
    func didUpdateUseCache(_ newUseCache: Bool)
    
    /// User updated the usage of imperial units
    func didUpdateUseImperial(_ newUseImperial: Bool)
    
    /// User updated the keep screen always on option
    func didUpdateKeepScreenAlwaysOn(_ newKeepScreenAlwaysOn: Bool)
    
    /// User updated the show scale bar option
    func didUpdateShowScaleBar(_ newShowScaleBar: Bool)
  
    /// User updated the activity type
    func didUpdateActivityType(_ newActivityType: Int)

    /// User updated the trackpoint recording interval
    func didUpdateTrackInterval(_ newIntervalSeconds: Double)

    /// User toggled charger mode (altijd hoogste GPS + max zoom)
    func didUpdateChargerMode(_ newChargerMode: Bool)

    /// User toggled wind overlay on/off
    func didUpdateShowWindOverlay(_ newValue: Bool)

    /// User toggled OWM overlay on/off and selected a layer
    func didUpdateShowOWMOverlay(_ newValue: Bool, layer: OWMLayer)

}
