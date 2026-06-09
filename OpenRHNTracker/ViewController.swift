//
//  ViewController.swift
//  OpenRHNTracker
//
//  Created by merlos on 13/09/14.
//
//  Localized by nitricware on 19/08/19.
//

import UIKit
import CoreLocation
import MapKit
import CoreGPX

// swiftlint:disable line_length

/// App title

let kAppTitle: String = "  RHN GPX TRACKER"
/// Purple color for button background
let kPurpleButtonBackgroundColor: UIColor =  UIColor(red: 146.0/255.0, green: 166.0/255.0, blue: 218.0/255.0, alpha: 0.90)

/// Green color for button background
let kGreenButtonBackgroundColor: UIColor = UIColor(red: 142.0/255.0, green: 224.0/255.0, blue: 102.0/255.0, alpha: 0.90)

/// Red color for button background
let kRedButtonBackgroundColor: UIColor =  UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.90)

/// Blue color for button background
let kBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.90)

/// Blue color for disabled button background
let kDisabledBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.10)

/// Red color for disabled button background
let kDisabledRedButtonBackgroundColor: UIColor =  UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.10)

/// White color for button background
let kWhiteBackgroundColor: UIColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)

/// Delete Waypoint Button tag. Used in a waypoint bubble
let kDeleteWaypointAccesoryButtonTag = 666

/// Edit Waypoint Button tag. Used in a waypoint bubble.
let kEditWaypointAccesoryButtonTag = 333

/// Text to display when the system is not providing coordinates.
let kNotGettingLocationText = NSLocalizedString("NO_LOCATION", comment: "no comment")

/// Text to display unknown accuracy
let kUnknownAccuracyText = "±···"

/// Text to display unknown speed.
let kUnknownSpeedText = "·.··"

/// Size for small buttons
let kButtonSmallSize: CGFloat = 48.0

/// Size for large buttons
let kButtonLargeSize: CGFloat = 96.0

/// Separation between buttons
let kButtonSeparation: CGFloat = 6.0

/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy6 = 6.0
/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy5 = 11.0
/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy4 = 31.0
/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy3 = 51.0
/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy2 = 101.0
/// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy1 = 201.0

///
/// Main View Controller of the Application. It is loaded when the application is launched
///
/// Displays a map and a set the buttons to control the tracking
///
///
class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    /// Shall the map be centered on current user position?
    /// If yes, whenever the user moves, the center of the map too.
    var followUser: Bool = true {
        didSet {
            if followUser {
                print("followUser=true")
                followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControl.State())
                map.setCenter((map.userLocation.coordinate), animated: true)
                // Herstel course-up als we al een heading hebben
                if let heading = lastTrueHeading {
                    let camera = map.camera
                    camera.heading = heading
                    map.setCamera(camera, animated: true)
                }
            } else {
                print("followUser=false")
                followUserButton.setImage(UIImage(named: "follow_user"), for: UIControl.State())
                // Terug naar north-up
                let camera = map.camera
                camera.heading = 0
                map.setCamera(camera, animated: true)
            }
        }
    }
    
    /// Last known true heading (degrees). Nil totdat CLLocationManager heading-updates binnenkomen.
    var lastTrueHeading: CLLocationDirection? = nil

    /// TBD (not currently used)
    var followUserBeforePinchGesture = true

    /// location manager instance configuration
    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestAlwaysAuthorization()
        manager.activityType = CLActivityType(rawValue: Preferences.shared.locationActivityTypeInt)!
        print("Chosen CLActivityType: \(manager.activityType.name)")
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2 // meters
        manager.headingFilter = 3 // degrees (1 is default)
        manager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            manager.allowsBackgroundLocationUpdates = true
        }
        return manager
    }()
    
    /// Map View
    var map: GPXMapView
    
    /// Map View delegate 
    let mapViewDelegate = MapViewDelegate()
    
    /// Stop watch instance to control elapsed time
    var stopWatch = StopWatch()

    /// Last time a trackpoint was recorded; used to honour `preferences.trackIntervalSeconds`.
    var lastTrackedDate: Date?

    /// Speed readings (timestamp + m/s) used to calculate average speed for map-zoom adaptation.
    var speedReadings: [(date: Date, speedMs: Double)] = []

    /// Fires every 10 s to adjust the map region based on recent average speed.
    var mapUpdateTimer: Timer?

    /// Watchdog timer: checks every 10s if GPS updates are still coming in.
    var gpsWatchdogTimer: Timer?

    /// Timestamp of the last received GPS location update. Used by watchdog to detect stale GPS.
    var lastGPSUpdateDate: Date?

    /// Huidige GPS-accuraatheid profiel (voor logging / debug)
    private var currentGPSProfile: String = ""
    
    /// Name of the last file that was saved (without extension)
    var lastGpxFilename: String = "" {
        didSet {
            if lastGpxFilename == "" {
                appTitleLabel.text = ""
            } else {
                // if name is too long arbitrary cut
                var displayedName = lastGpxFilename
                if lastGpxFilename.count > 20 {
                    displayedName = lastGpxFilename.prefix(10) + "..." + lastGpxFilename.suffix(3)
                }
                appTitleLabel.text = ""
                // Toon bestandsnaam in middelste balk (tweede regel)
                windInfoLabel.attributedText = self.bvkTitleAttributedText(subtitle: displayedName + ".gpx")
            }
        }
    }
    
    /// Status variable that indicates if the app was sent to background.
    var wasSentToBackground: Bool = false
    
    /// Status variable that indicates if the location service auth was denied.
    var isDisplayingLocationServicesDenied: Bool = false
    
    /// Has the map any waypoint?
    var hasWaypoints: Bool = false {
        /// Whenever it is updated, if it has waypoints it sets the save and reset button
        didSet {
            if hasWaypoints {
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
            }
        }
    }

    /// Defines the different statuses regarding tracking current user location.
    enum GpxTrackingStatus {
        
        /// Tracking has not started or map was reset
        case notStarted
        
        /// Tracking is ongoing
        case tracking
        
        /// Tracking is paused (the map has some contents)
        case paused
    }
    
    /// Tells what is the current status of the Map Instance.
    var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.notStarted {
        didSet {
            print("gpxTrackingStatus changed to \(gpxTrackingStatus)")
            switch gpxTrackingStatus {
            case .notStarted:
                print("switched to non started")
                // Set tracker button to allow Start
                trackerButton.setTitle(NSLocalizedString("START_TRACKING", comment: "no comment"), for: UIControl.State())
                trackerButton.backgroundColor = kGreenButtonBackgroundColor
                // Save & reset button to transparent.
                saveButton.backgroundColor = kDisabledBlueButtonBackgroundColor
                resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
                // Reset clock
                stopWatch.reset()
                timeLabel.text = stopWatch.elapsedTimeString

                map.clearMap()        // Clear map
                lastGpxFilename = "" // Clear last filename, so when saving it appears an empty field

                map.coreDataHelper.clearAll()
                map.coreDataHelper.coreDataDeleteAll(of: CDRoot.self) // deleteCDRootFromCoreData()

                totalTrackedDistanceLabel.distance = (map.session.totalTrackedDistance)
                currentSegmentDistanceLabel.distance = (map.session.currentSegmentDistance)

                // Stop speed-based zoom so it doesn't keep adjusting after reset
                stopMapUpdateTimer()
                speedReadings = []
                
                /*
                // XXX Left here for reference
                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    self.trackerButton.hidden = true
                    self.pauseButton.hidden = false
                    }, completion: {(f: Bool) -> Void in
                        println("finished animation start tracking")
                })
                */
                
            case .tracking:
                print("switched to tracking mode")
                lastTrackedDate = nil
                // set tracerkButton to allow Pause
                trackerButton.setTitle(NSLocalizedString("PAUSE", comment: "no comment"), for: UIControl.State())
                trackerButton.backgroundColor = kPurpleButtonBackgroundColor
                // Activate save & reset buttons
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
                // start clock
                self.stopWatch.start()
                // (Re)start speed-based map zoom timer
                startMapUpdateTimer()
                
            case .paused:
                print("switched to paused mode")
                // set trackerButton to allow Resume
                self.trackerButton.setTitle(NSLocalizedString("RESUME", comment: "no comment"), for: UIControl.State())
                self.trackerButton.backgroundColor = kGreenButtonBackgroundColor
                // activate save & reset (just in case switched from .NotStarted)
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
                // Pause clock
                self.stopWatch.stop()
                // start new track segment
                self.map.startNewTrackSegment()
                // Stop speed-based zoom while paused and clear readings so
                // zoom rebuilds cleanly from fresh data when recording resumes
                stopMapUpdateTimer()
                speedReadings = []
            }
        }
    }

    /// Editing Waypoint Temporal Reference
    var lastLocation: CLLocation? // Last point of current segment.

    // UI
    /// Label with the title of the app
    var appTitleLabel: UILabel

    /// Image with the GPS signal
    var signalImageView: UIImageView
    
    /// Current GPS signal accuracy text (based on kSignalAccuracyX constants)
    var signalAccuracyLabel: UILabel
    
    /// Label that displays current latitude and longitude (lat,long)
    var coordsLabel: UILabel

    /// Tweede info-rij: links — temperatuur + zichtbaarheid
    var tempVisLabel: UILabel

    /// Tweede info-rij: midden — luchtdruk + trend
    var pressureLabel: UILabel

    /// Tweede info-rij: rechts — golfhoogte + periode
    var waveLabel: UILabel

    /// Midden-kolom in de coördinaten-balk: wind (richting, Beaufort, knoten)
    var windInfoLabel: UILabel

    /// Timer that refreshes wind data every 5 minutes
    var windUpdateTimer: Timer?

    /// Rechter kolom in de coördinaten-balk: waterstand NAP (Rijkswaterstaat)
    var waterInfoLabel: UILabel

    /// Timer that refreshes waterstand every 10 minutes
    var waterstandTimer: Timer?

    /// Laatste windsnelheid (knoten) en richting (graden) voor stroming berekening
    var lastWindSpeedKn: Double = 0
    var lastWindDirDeg: Double = 0


    /// Displays current elapsed time (00:00)
    var timeLabel: UILabel
    
    /// Label that displays last known speed (in km/h)
    var speedLabel: UILabel
    
    /// Distance of the total segments tracked
    var totalTrackedDistanceLabel: DistanceLabel
    
    /// Distance of the current segment being tracked (since last time the Tracker button was pressed)
    var currentSegmentDistanceLabel: DistanceLabel
 
    /// Used to display in imperial (foot, miles, mph) or metric system (m, km, km/h)
    var useImperial = false
    
    /// Follow user button (bottom bar)
    var followUserButton: UIButton
    
    /// New pin button (bottom bar)
    var newPinButton: UIButton
    
    /// View GPX Files button
    var folderButton: UIButton
    
    /// View app about button
    var aboutButton: UIButton
    
    /// View preferences button
    var preferencesButton: UIButton
    
    /// Share current gpx file button
    var shareButton: UIButton

    
    /// Spinning Activity Indicator for shareButton
    let shareActivityIndicator: UIActivityIndicatorView
    
    /// Spinning Activity Indicator's color
    var shareActivityColor = UIColor(red: 0, green: 0.61, blue: 0.86, alpha: 1)
    
    /// Reset map button (bottom bar)
    var resetButton: UIButton
    
    /// Start/Pause tracker button (bottom bar)
    var trackerButton: UIButton
    
    /// Save current track into a GPX file
    var saveButton: UIButton
	
	/// Scale Bar View
    var scaleBar: GPXScaleBar
    
    /// Check if device is notched type phone
    var isIPhoneX = false
    
    // Signal accuracy images
    /// GPS signal image. Level 0 (no signal)
    let signalImage0 = UIImage(named: "signal0")
    /// GPS signal image. Level 1
    let signalImage1 = UIImage(named: "signal1")
    /// GPS signal image. Level 2
    let signalImage2 = UIImage(named: "signal2")
    /// GPS signal image. Level 3
    let signalImage3 = UIImage(named: "signal3")
    /// GPS signal image. Level 4
    let signalImage4 = UIImage(named: "signal4")
    /// GPS signal image. Level 5
    let signalImage5 = UIImage(named: "signal5")
    /// GPS signal image. Level 6
    let signalImage6 = UIImage(named: "signal6")
 
    /// Initializer. Just initializes the class vars/const
    required init(coder aDecoder: NSCoder) {
        self.map = GPXMapView(frame: .zero)

        self.appTitleLabel = UILabel()
        self.signalImageView = UIImageView()
        self.signalAccuracyLabel = UILabel()
        self.coordsLabel = UILabel()
        self.tempVisLabel = UILabel()
        self.pressureLabel = UILabel()
        self.waveLabel = UILabel()
        self.windInfoLabel = UILabel()
        self.waterInfoLabel = UILabel()

        self.timeLabel = UILabel()
        self.speedLabel = UILabel()
        self.totalTrackedDistanceLabel = DistanceLabel()
        self.currentSegmentDistanceLabel = DistanceLabel()

        self.followUserButton = UIButton(type: .custom)
        self.newPinButton = UIButton(type: .custom)
        self.folderButton = UIButton(type: .custom)
        self.resetButton = UIButton(type: .custom)
        self.aboutButton = UIButton(type: .custom)
        self.preferencesButton = UIButton(type: .custom)
        self.shareButton = UIButton(type: .custom)
        self.trackerButton = UIButton(type: .custom)
        self.saveButton = UIButton(type: .custom)

        self.shareActivityIndicator = UIActivityIndicatorView()
        self.scaleBar = GPXScaleBar()
        super.init(coder: aDecoder)!
    }
    
    ///
    /// De initalize the ViewController.
    ///
    /// Current implementation removes notification observers
    ///
    deinit {
        print("*** deinit")
        NotificationCenter.default.removeObserver(self)
    }
   
    /// Handles status bar color as a result from iOS 13 appearance changes
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13, *) {
            if !isIPhoneX {
                if self.traitCollection.userInterfaceStyle == .dark && map.tileServer == .apple {
                    self.view.backgroundColor = .black
                    return .lightContent
                } else {
                    self.view.backgroundColor = .white
                    return .darkContent
                }
            } else { // > iPhone X has no opaque status bar
                // if is > iP X status bar can be white when map is dark
                return map.tileServer == .apple ? .default : .darkContent
            }
        } else { // < iOS 13
            return .default
        }
    }
    
    ///
    /// Initializes the view. It adds the UI elements to the view.
    ///
    /// All the UI is built programatically on this method. Interface builder is not used.
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        stopWatch.delegate = self
        
        map.coreDataHelper.retrieveFromCoreData()
        
        // Because of the edges, iPhone X* is slightly different on the layout.
        // So, Is the current device an iPhone X?
        if UIDevice.current.userInterfaceIdiom == .phone, #available(iOS 11, *) {
            self.isIPhoneX = UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 40
        }
        
        // Map autorotate configuration
        map.autoresizesSubviews = true
        map.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.autoresizesSubviews = true
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        // Map configuration Stuff
        map.delegate = mapViewDelegate
        map.showsUserLocation = true
        let mapH: CGFloat = self.view.bounds.size.height - (isIPhoneX ? 0.0 : 20.0)
        map.frame = CGRect(x: 0.0, y: (isIPhoneX ? 0.0 : 20.0), width: self.view.bounds.size.width, height: mapH)
        map.isZoomEnabled = true
        map.isRotateEnabled = true
        // Set the position of the compass.
        map.compassRect = CGRect(x: map.frame.width/2 - 18, y: isIPhoneX ? 105.0 : 70.0, width: 36, height: 36)
        
        // If user long presses the map, it will add a Pin (waypoint) at that point
        map.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addPinAtTappedLocation(_:)))
        )
        
        // Each time user pans, if the map is following the user, it stops doing that.
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        panGesture.delegate = self
        map.addGestureRecognizer(panGesture)
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        startGPSWatchdog()
        startWindTimer()
        startWaterstandTimer()
        locationManager.startUpdatingHeading()
        startMapUpdateTimer()

        // Preferences
        map.tileServer = Preferences.shared.tileServer
        map.useCache = Preferences.shared.useCache
        map.showWindOverlay = Preferences.shared.showWindOverlay
        map.showOWMOverlay = Preferences.shared.showOWMOverlay
        useImperial = Preferences.shared.useImperial
        // LocationManager.activityType = Preferences.shared.locationActivityType
        
        // Shall it keep the screen always on?
        UIApplication.shared.isIdleTimerDisabled = Preferences.shared.keepScreenAlwaysOn
        
        //
        // Config user interface
        //
        
        // Set default zoom
        let center = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 8.90, longitude: -79.50)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
        self.view.addSubview(map)
        
        addNotificationObservers()
        
        //
        // ---------------------- Build Interface Area -----------------------------
        //
        // HEADER
        let font36 = UIFont(name: "DinCondensed-Bold", size: 36.0)
        let font18 = UIFont(name: "DinAlternate-Bold", size: 18.0)
        let font12 = UIFont(name: "DinAlternate-Bold", size: 12.0)
        
        // Add the app title Label (Branding, branding, branding! )
        // appTitleLabel verborgen — titel staat nu in windInfoLabel (middelste kolom)
        appTitleLabel.text = ""
        appTitleLabel.isHidden = true
        appTitleLabel.backgroundColor = .clear
        self.view.addSubview(appTitleLabel)
        
        // CoordLabel
        coordsLabel.textAlignment = .left
        coordsLabel.font = UIFont(name: "DinAlternate-Bold", size: 16.0)
        coordsLabel.adjustsFontSizeToFitWidth = true
        coordsLabel.minimumScaleFactor = 0.8
        coordsLabel.numberOfLines = 2
        coordsLabel.textColor = UIColor.white
        coordsLabel.backgroundColor = UIColor(red: 58.0/255.0, green: 57.0/255.0, blue: 54.0/255.0, alpha: 0.80)
        coordsLabel.text = kNotGettingLocationText
        self.view.addSubview(coordsLabel)
        
        // Tracked info
        let iPhoneXdiff: CGFloat  = isIPhoneX ? 40 : 0
        
        // TimeLabel
        timeLabel.textAlignment = .right
        timeLabel.font = font36
        timeLabel.text = "00:00"
        map.addSubview(timeLabel)
        
        // Speed Label
        speedLabel.textAlignment = .right
        speedLabel.font = font18
        speedLabel.text = 0.00.toSpeed(useImperial: useImperial)
        map.addSubview(speedLabel)
        
        // Tracked distance
        totalTrackedDistanceLabel.textAlignment = .right
        totalTrackedDistanceLabel.font = font36
        totalTrackedDistanceLabel.useImperial = useImperial
        totalTrackedDistanceLabel.distance = 0.00
        totalTrackedDistanceLabel.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        map.addSubview(totalTrackedDistanceLabel)
        
        currentSegmentDistanceLabel.textAlignment = .right
        currentSegmentDistanceLabel.font = font18
        currentSegmentDistanceLabel.useImperial = useImperial
        currentSegmentDistanceLabel.distance = 0.00
        currentSegmentDistanceLabel.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        map.addSubview(currentSegmentDistanceLabel)
        
        // About button
        aboutButton.frame = CGRect(x: 5 + 8, y: 14 + 5 + 48 + 5 + iPhoneXdiff, width: 32, height: 32)
        aboutButton.setImage(UIImage(named: "info"), for: UIControl.State())
        aboutButton.setImage(UIImage(named: "info_high"), for: .highlighted)
        aboutButton.addTarget(self, action: #selector(ViewController.openAboutViewController), for: .touchUpInside)
        aboutButton.autoresizingMask = [.flexibleRightMargin]
        map.addSubview(aboutButton)
        
        // Preferences button
        preferencesButton.frame = CGRect(x: 5 + 10 + 48, y: 14 + 5 + 8  + iPhoneXdiff, width: 32, height: 32)
        preferencesButton.setImage(UIImage(named: "prefs"), for: UIControl.State())
        preferencesButton.setImage(UIImage(named: "prefs_high"), for: .highlighted)
        preferencesButton.addTarget(self, action: #selector(ViewController.openPreferencesTableViewController), for: .touchUpInside)
        preferencesButton.autoresizingMask = [.flexibleRightMargin]
        map.addSubview(preferencesButton)
        
        // Share button
        shareButton.frame = CGRect(x: 5 + 10 + 48 * 2, y: 14 + 5 + 8  + iPhoneXdiff, width: 32, height: 32)
        shareButton.setImage(UIImage(named: "share"), for: UIControl.State())
        shareButton.setImage(UIImage(named: "share_high"), for: .highlighted)
        shareButton.addTarget(self, action: #selector(ViewController.openShare), for: .touchUpInside)
        shareButton.autoresizingMask = [.flexibleRightMargin]
        map.addSubview(shareButton)

        
        // Folder button
        let folderW: CGFloat = kButtonSmallSize
        let folderH: CGFloat = kButtonSmallSize
        let folderX: CGFloat = folderW/2 + 5
        let folderY: CGFloat = folderH/2 + 5 + 14  + iPhoneXdiff
        folderButton.frame = CGRect(x: 0, y: 0, width: folderW, height: folderH)
        folderButton.center = CGPoint(x: folderX, y: folderY)
        folderButton.setImage(UIImage(named: "folder"), for: UIControl.State())
        folderButton.setImage(UIImage(named: "folderHigh"), for: .highlighted)
        folderButton.addTarget(self, action: #selector(ViewController.openFolderViewController), for: .touchUpInside)
        folderButton.backgroundColor = kWhiteBackgroundColor
        folderButton.layer.cornerRadius = 24
        folderButton.autoresizingMask = [.flexibleRightMargin]
        map.addSubview(folderButton)
        
        // Add signal accuracy images and labels
        signalImageView.image = signalImage0
        signalImageView.frame = CGRect(x: self.view.frame.width/2 - 25.0, y: 14 + 5 + iPhoneXdiff, width: 50, height: 30)
        map.addSubview(signalImageView)
        signalAccuracyLabel.frame = CGRect(x: self.view.frame.width/2 - 25.0, y: 14 + 5 + 30 + iPhoneXdiff, width: 50, height: 12)
        signalAccuracyLabel.font = font12
        signalAccuracyLabel.text = kUnknownAccuracyText
        signalAccuracyLabel.textAlignment = .center
        map.addSubview(signalAccuracyLabel)

        // Tweede rij — gedeelde stijl
        let kBarBg = UIColor(red: 58.0/255.0, green: 57.0/255.0, blue: 54.0/255.0, alpha: 0.80)
        let kBarFont = UIFont(name: "DinAlternate-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16)

        tempVisLabel.font = kBarFont
        tempVisLabel.textColor = .white
        tempVisLabel.backgroundColor = kBarBg
        tempVisLabel.textAlignment = .left
        tempVisLabel.numberOfLines = 2
        tempVisLabel.adjustsFontSizeToFitWidth = true
        tempVisLabel.minimumScaleFactor = 0.7
        tempVisLabel.text = "  --°C\n  -- km"
        self.view.addSubview(tempVisLabel)

        pressureLabel.font = kBarFont
        pressureLabel.textColor = .white
        pressureLabel.backgroundColor = kBarBg
        pressureLabel.textAlignment = .center
        pressureLabel.numberOfLines = 2
        pressureLabel.adjustsFontSizeToFitWidth = true
        pressureLabel.minimumScaleFactor = 0.7
        pressureLabel.text = "---- hPa\n→ stabiel"
        self.view.addSubview(pressureLabel)

        waveLabel.font = kBarFont
        waveLabel.textColor = .white
        waveLabel.backgroundColor = kBarBg
        waveLabel.textAlignment = .right
        waveLabel.numberOfLines = 2
        waveLabel.adjustsFontSizeToFitWidth = true
        waveLabel.minimumScaleFactor = 0.7
        waveLabel.text = "-- m\n-- s periode"
        self.view.addSubview(waveLabel)

        // Wind label — midden kolom in de coördinaten-balk
        windInfoLabel.font = UIFont(name: "DinAlternate-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16)
        windInfoLabel.textColor = UIColor.white
        windInfoLabel.backgroundColor = UIColor(red: 58.0/255.0, green: 57.0/255.0, blue: 54.0/255.0, alpha: 0.80)
        windInfoLabel.textAlignment = .center
        windInfoLabel.numberOfLines = 2
        windInfoLabel.attributedText = bvkTitleAttributedText(subtitle: "-- · -- kn")
        windInfoLabel.adjustsFontSizeToFitWidth = true
        windInfoLabel.minimumScaleFactor = 0.7
        self.view.addSubview(windInfoLabel)

        // Waterstand label — rechter kolom in de coördinaten-balk
        waterInfoLabel.font = UIFont(name: "DinAlternate-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16)
        waterInfoLabel.textColor = UIColor.white
        waterInfoLabel.backgroundColor = UIColor(red: 58.0/255.0, green: 57.0/255.0, blue: 54.0/255.0, alpha: 0.80)
        waterInfoLabel.textAlignment = .right
        waterInfoLabel.numberOfLines = 2
        waterInfoLabel.text = "--\n-- cm NAP"
        waterInfoLabel.adjustsFontSizeToFitWidth = true
        waterInfoLabel.minimumScaleFactor = 0.7
        self.view.addSubview(waterInfoLabel)

        //
        // Button Bar
        //
        // [ Small ] [ Small ] [ Large     ] [Small] [ Small]
        //                     [ (tracker) ]
        //
        //                     [ track     ]
        // [ follow] [ +Pin  ] [ Pause     ] [ Save ] [ Reset]
        //                     [ Resume    ]
        //
        //                       trackerX
        //                         |
        //                         |
        // [-----------------------|--------------------------]
        //                  map.frame/2 (center)

        // Start/Pause button
        trackerButton.layer.cornerRadius = kButtonLargeSize/2
        trackerButton.setTitle(NSLocalizedString("START_TRACKING", comment: "no comment"), for: UIControl.State())
        trackerButton.backgroundColor = kGreenButtonBackgroundColor
        trackerButton.addTarget(self, action: #selector(ViewController.trackerButtonTapped), for: .touchUpInside)
        trackerButton.isHidden = false
        trackerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        trackerButton.titleLabel?.numberOfLines = 2
        trackerButton.titleLabel?.textAlignment = .center
        map.addSubview(trackerButton)
        
        // Pin Button (on the left of start)
        newPinButton.layer.cornerRadius = kButtonSmallSize/2
        newPinButton.backgroundColor = kWhiteBackgroundColor
        newPinButton.setImage(UIImage(named: "addPin"), for: UIControl.State())
        newPinButton.setImage(UIImage(named: "addPinHigh"), for: .highlighted)
        newPinButton.addTarget(self, action: #selector(ViewController.addPinAtMyLocation), for: .touchUpInside)
        map.addSubview(newPinButton)
        
        // Follow user button
        followUserButton.layer.cornerRadius = kButtonSmallSize/2
        followUserButton.backgroundColor = kWhiteBackgroundColor
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControl.State())
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: .highlighted)
        followUserButton.addTarget(self, action: #selector(ViewController.followButtonTroggler), for: .touchUpInside)
        map.addSubview(followUserButton)
        
        // Save button
        saveButton.layer.cornerRadius = kButtonSmallSize/2
        saveButton.setTitle(NSLocalizedString("SAVE", comment: "no comment"), for: UIControl.State())
        saveButton.backgroundColor = kDisabledBlueButtonBackgroundColor
        saveButton.addTarget(self, action: #selector(ViewController.saveButtonTapped), for: .touchUpInside)
        saveButton.isHidden = false
        saveButton.titleLabel?.textAlignment = .center
        saveButton.titleLabel?.adjustsFontSizeToFitWidth = true
        map.addSubview(saveButton)
        
        // Reset button
        resetButton.layer.cornerRadius = kButtonSmallSize/2
        resetButton.setTitle(NSLocalizedString("RESET", comment: "no comment"), for: UIControl.State())
        resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
        resetButton.addTarget(self, action: #selector(ViewController.resetButtonTapped), for: .touchUpInside)
        resetButton.isHidden = false
        resetButton.titleLabel?.textAlignment = .center
        resetButton.titleLabel?.adjustsFontSizeToFitWidth = true
        map.addSubview(resetButton)
        
        addConstraints(isIPhoneX)
        
        map.rotationGesture.delegate = self
        updateAppearance()
        
        if #available(iOS 13, *) {
            shareActivityColor = .mainUIColor
		}
		
		let compassButton = MKCompassButton(mapView: map)
		self.view.addSubview(compassButton)
		compassButton.translatesAutoresizingMaskIntoConstraints = false
		addConstraintsToCompassView(compassButton)
		
		self.textColorAdaptations()
		
		addScaleBarOnTopOfTrackButton()
    }
	
    // MARK: - Add Constraints for views
    /// Adds Constraints to subviews
    ///
    /// The constraints will ensure that subviews will be positioned correctly, when there are orientation changes, or iPad split view width changes.
    ///
    /// - Parameters:
    ///     - isIPhoneX: if device is >= iPhone X, bottom gap will be zero
    func addConstraints(_ isIPhoneX: Bool) {
        addConstraintsToAppTitleBar()
        addConstraintsToTopInteractableElements()
        addConstraintsToButtonBar(isIPhoneX)
    }
    
    /// Adds constraints to subviews forming the app title bar (top bar)
    func addConstraintsToAppTitleBar() {
        // MARK: App Title Bar
        
        // Switch off all autoresizing masks translate
        appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        coordsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        let safeAreaInsets = self.view.safeAreaInsets
        
        // appTitleLabel: dunne bovenste balk
        NSLayoutConstraint(item: appTitleLabel, attribute: .top, relatedBy: .equal, toItem: safeAreaGuide, attribute: .top, multiplier: 1, constant: safeAreaInsets.top).isActive = true
        NSLayoutConstraint(item: appTitleLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: appTitleLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: appTitleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0).isActive = true
        // coordsLabel: linker kolom — vaste breedte 1/3 van scherm
        NSLayoutConstraint(item: coordsLabel, attribute: .top, relatedBy: .equal, toItem: appTitleLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: coordsLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: coordsLabel, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0/3.0, constant: 0).isActive = true

        // windInfoLabel: midden kolom — gecentreerd
        windInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: windInfoLabel, attribute: .top, relatedBy: .equal, toItem: appTitleLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: windInfoLabel, attribute: .leading, relatedBy: .equal, toItem: coordsLabel, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: windInfoLabel, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0/3.0, constant: 0).isActive = true
        NSLayoutConstraint(item: windInfoLabel, attribute: .height, relatedBy: .equal, toItem: coordsLabel, attribute: .height, multiplier: 1, constant: 0).isActive = true

        // waterInfoLabel: rechter kolom — rechts uitgelijnd
        waterInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: waterInfoLabel, attribute: .top, relatedBy: .equal, toItem: appTitleLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: waterInfoLabel, attribute: .leading, relatedBy: .equal, toItem: windInfoLabel, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: waterInfoLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -4).isActive = true
        NSLayoutConstraint(item: waterInfoLabel, attribute: .height, relatedBy: .equal, toItem: coordsLabel, attribute: .height, multiplier: 1, constant: 0).isActive = true

        // Tweede rij — direct onder de eerste balk
        tempVisLabel.translatesAutoresizingMaskIntoConstraints = false
        pressureLabel.translatesAutoresizingMaskIntoConstraints = false
        waveLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint(item: tempVisLabel, attribute: .top, relatedBy: .equal, toItem: coordsLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: tempVisLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: tempVisLabel, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0/3.0, constant: 0).isActive = true

        NSLayoutConstraint(item: pressureLabel, attribute: .top, relatedBy: .equal, toItem: coordsLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: pressureLabel, attribute: .leading, relatedBy: .equal, toItem: tempVisLabel, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: pressureLabel, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0/3.0, constant: 0).isActive = true
        NSLayoutConstraint(item: pressureLabel, attribute: .height, relatedBy: .equal, toItem: tempVisLabel, attribute: .height, multiplier: 1, constant: 0).isActive = true

        NSLayoutConstraint(item: waveLabel, attribute: .top, relatedBy: .equal, toItem: coordsLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: waveLabel, attribute: .leading, relatedBy: .equal, toItem: pressureLabel, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: waveLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -4).isActive = true
        NSLayoutConstraint(item: waveLabel, attribute: .height, relatedBy: .equal, toItem: tempVisLabel, attribute: .height, multiplier: 1, constant: 0).isActive = true
    }
    
    /// Adds constraints to subviews forming the informational labels (top right side; i.e. speed, elapse time labels)
    func addConstraintsToTopInteractableElements() {
        // MARK: Information Labels (on right)
        
        /// offset from center, without obstructing signal view
        let kSignalViewOffset: CGFloat = 25
        
        // Switch off all autoresizing masks translate
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTrackedDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        currentSegmentDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        
        NSLayoutConstraint(item: timeLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: timeLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        // self.topLayoutGuide takes care of the iPhone X safe area, iPhoneXdiff not needed
        NSLayoutConstraint(item: timeLabel, attribute: .top, relatedBy: .equal, toItem: self.tempVisLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        
        NSLayoutConstraint(item: speedLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: speedLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: speedLabel, attribute: .top, relatedBy: .equal, toItem: timeLabel, attribute: .bottom, multiplier: 1, constant: -5).isActive = true
        
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .top, relatedBy: .equal, toItem: speedLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .top, relatedBy: .equal, toItem: totalTrackedDistanceLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        
        // MARK: Signal Chart & Label (on center)
        
        signalImageView.translatesAutoresizingMaskIntoConstraints = false
        signalAccuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: signalImageView, attribute: .centerX, relatedBy: .equal, toItem: safeAreaGuide, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .top, relatedBy: .equal, toItem: self.tempVisLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30).isActive = true
        NSLayoutConstraint(item: signalAccuracyLabel, attribute: .centerX, relatedBy: .equal, toItem: safeAreaGuide, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: signalAccuracyLabel, attribute: .top, relatedBy: .equal, toItem: signalImageView, attribute: .bottom, multiplier: 1, constant: 2).isActive = true
        
        // MARK: Buttons (on left)
        
        folderButton.translatesAutoresizingMaskIntoConstraints = false
        preferencesButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: folderButton, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .top, relatedBy: .equal, toItem: tempVisLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: kButtonSmallSize).isActive = true
        
        NSLayoutConstraint(item: preferencesButton, attribute: .centerY, relatedBy: .equal, toItem: folderButton, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .leading, relatedBy: .equal, toItem: folderButton, attribute: .trailing, multiplier: 1, constant: 10).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true
        
        NSLayoutConstraint(item: shareButton, attribute: .centerY, relatedBy: .equal, toItem: folderButton, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .leading, relatedBy: .equal, toItem: preferencesButton, attribute: .trailing, multiplier: 1, constant: 10).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true
        
        NSLayoutConstraint(item: aboutButton, attribute: .top, relatedBy: .equal, toItem: folderButton, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .centerX, relatedBy: .equal, toItem: folderButton, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true

    }
    
    /// Adds constraints to subviews forming the button bar (bottom session controls bar)
    func addConstraintsToButtonBar(_ isIPhoneX: Bool) {
        // MARK: Button Bar
        
        // constants
        let kBottomGap: CGFloat = isIPhoneX ? 0 : 15
        let kBottomDistance: CGFloat = kBottomGap + 24
        
        // Switch off all autoresizing masks translate
        trackerButton.translatesAutoresizingMaskIntoConstraints = false
        newPinButton.translatesAutoresizingMaskIntoConstraints = false
        followUserButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        
        // set trackerButton to horizontal center of view
        NSLayoutConstraint(item: trackerButton, attribute: .centerX, relatedBy: .equal, toItem: map, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        
        // seperation distance between each button
        NSLayoutConstraint(item: trackerButton, attribute: .leading, relatedBy: .equal, toItem: newPinButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .leading, relatedBy: .equal, toItem: followUserButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .leading, relatedBy: .equal, toItem: trackerButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .leading, relatedBy: .equal, toItem: saveButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true

        // seperation distance between button and bottom of view
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: followUserButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: newPinButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: trackerButton, attribute: .bottom, multiplier: 1, constant: kBottomGap).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: saveButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: resetButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        
        // fixed dimensions for all buttons
        NSLayoutConstraint(item: followUserButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: followUserButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: trackerButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonLargeSize).isActive = true
        NSLayoutConstraint(item: trackerButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonLargeSize).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
    }
	
	private func addScaleBarOnTopOfTrackButton() {
        scaleBar = GPXScaleBar(mapView: map, useImperial: Preferences.shared.useImperial)
        view.addSubview(scaleBar)
        
        map.scaleBar = scaleBar
		scaleBar.translatesAutoresizingMaskIntoConstraints = false
        
		NSLayoutConstraint.activate([
			scaleBar.centerXAnchor.constraint(
				equalTo: trackerButton.centerXAnchor,
                constant: -scaleBar.frame.width / 2
			),
			scaleBar.bottomAnchor.constraint(
				equalTo: trackerButton.topAnchor,
				constant: -36
			)
		])
        
        textColorAdaptations()
	}
    
    @available(iOS 11, *)
    func addConstraintsToCompassView(_ view: MKCompassButton) {
        NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.signalAccuracyLabel, attribute: .bottom, multiplier: 1, constant: 8).isActive = true
        
        NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
    }
    
    /// For handling compass location changes when orientation is switched.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async {
            // set the new position of the compass.
            self.map.compassRect = CGRect(x: size.width/2 - 18, y: 70.0, width: 36, height: 36)
            // update compass frame location
            self.map.layoutSubviews()
        }
        
    }
    
    /// Will update polyline color when invoked
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updatePolylineColor()
    }
    
    /// Updates polyline color
    func updatePolylineColor() {
        
        for overlay in map.overlays where overlay is MKPolyline {
            map.removeOverlay(overlay)
            map.addOverlayOnTop(overlay)
        }
    }
    
    ///
    /// Asks the system to notify the app on some events
    ///
    /// Current implementation requests the system to notify the app:
    ///
    ///  1. whenever it enters background
    ///  2. whenever it becomes active
    ///  3. whenever it will terminate
    ///  4. whenever it receives a file from Apple Watch
    ///  5. whenever it should load file from Core Data recovery mechanism
    ///
    func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(ViewController.didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
       
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)

        notificationCenter.addObserver(self, selector: #selector(presentReceivedFile(_:)), name: .didReceiveFileFromAppleWatch, object: nil)

        notificationCenter.addObserver(self, selector: #selector(loadRecoveredFile(_:)), name: .loadRecoveredFile, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(updateAppearance), name: .updateAppearance, object: nil)
    }
    
    /// To update appearance when mapView requests to do so
    @objc func updateAppearance() {
        if #available(iOS 13, *) {
            setNeedsStatusBarAppearanceUpdate()
            updatePolylineColor()
        }
    }
    
    ///
    /// Presents alert when file received from Apple Watch
    ///
    @objc func presentReceivedFile(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let fileName = notification.userInfo?["fileName"] as? String? else { return }
            // alert to display to notify user that file has been received.
            let alertTitle = NSLocalizedString("WATCH_FILE_RECEIVED_TITLE", comment: "no comment")
            let alertMessage = NSLocalizedString("WATCH_FILE_RECEIVED_MESSAGE", comment: "no comment")
            let controller = UIAlertController(title: alertTitle, message: String(format: alertMessage, fileName ?? ""), preferredStyle: .alert)
            let action = UIAlertAction(title: NSLocalizedString("DONE", comment: "no comment"), style: .default) { _ in
                print("ViewController:: Presented file received message from WatchConnectivity Session")
            }
            
            controller.addAction(action)
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    /// Returns a string with the format of current date dd-MMM-yyyy-HHmm' (20-Jun-2018-1133)
    ///
    func defaultFilename() -> String {
        let defaultDate = DefaultDateFormat()
        let dateStr = defaultDate.getDateFromPrefs()
        print("fileName:" + dateStr)
        return dateStr
    }
    
    @objc func loadRecoveredFile(_ notification: Notification) {
        guard let root = notification.userInfo?["recoveredRoot"] as? GPXRoot else {
            return
        }
        guard let fileName = notification.userInfo?["fileName"] as? String else {
            return
        }

        lastGpxFilename = fileName
        // Adds last file name to core data as well
        self.map.coreDataHelper.add(toCoreData: fileName, willContinueAfterSave: false)
        // Force reset timer just in case reset does not do it
        self.stopWatch.reset()
        // Load data
        self.map.continueFromGPXRoot(root)
        // Stop following user
        self.followUser = false
        // Center map in GPX data
        self.map.regionToGPXExtent()
        self.gpxTrackingStatus = .paused
        
        self.totalTrackedDistanceLabel.distance = self.map.session.totalTrackedDistance
    }
    
    ///
    /// Called when the application Becomes active (background -> foreground) this function verifies if
    /// it has permissions to get the location.
    ///
    @objc func applicationDidBecomeActive() {
        DispatchQueue.global().async {
            print("viewController:: applicationDidBecomeActive wasSentToBackground: \(self.wasSentToBackground) locationServices: \(CLLocationManager.locationServicesEnabled())")
        }

        // If the app was never sent to background do nothing
        if !wasSentToBackground {
            return
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        startMapUpdateTimer()
        startGPSWatchdog()
        startWindTimer()
        startWaterstandTimer()
    }

    ///
    /// Actions to do in case the app entered in background
    ///
    /// In current implementation if the app is not tracking it requests the OS to stop
    /// sharing the location to save battery.
    ///
    ///
    @objc func didEnterBackground() {
        wasSentToBackground = true // flag the application was sent to background
        print("viewController:: didEnterBackground")
        if gpxTrackingStatus != .tracking {
            locationManager.stopUpdatingLocation()
            stopGPSWatchdog()
        }
        stopMapUpdateTimer()
        stopWindTimer()
        stopWaterstandTimer()
    }

    ///
    /// Actions to do when the app will terminate
    ///
    /// In current implementation it removes all the temporary files that may have been created
    @objc func applicationWillTerminate() {
        print("viewController:: applicationWillTerminate")
        GPXFileManager.removeTemporaryFiles()
        if gpxTrackingStatus == .notStarted {
            map.coreDataHelper.coreDataDeleteAll(of: CDTrackpoint.self)
            map.coreDataHelper.coreDataDeleteAll(of: CDWaypoint.self)
        }
    }
    
    ///
    /// Displays the view controller with the list of GPX Files.
    ///
    @objc func openFolderViewController() {
        print("openFolderViewController")
        let vc = GPXFilesTableViewController(nibName: nil, bundle: nil)
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
    }
    
    ///
    /// Displays the view controller with the About information.
    ///
    @objc func openAboutViewController() {
        let vc = AboutViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
    }

    ///
    /// Opens Preferences table view controller
    ///
    @objc func openPreferencesTableViewController() {
        print("openPreferencesTableViewController")
        let vc = PreferencesTableViewController(style: .grouped)
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true)
    }

    ///
    /// Opens an Activity View Controller to share the file
    /// 
    @objc func openShare() {
        print("ViewController: Share Button tapped")
        
        // async such that process is done in background
        DispatchQueue.global(qos: .utility).async {
            // UI code
            DispatchQueue.main.sync {
                self.shouldShowShareActivityIndicator(true)
            }
            
            // Create a temporary file
            let filename =  self.lastGpxFilename.isEmpty ? self.defaultFilename() : self.lastGpxFilename
            let gpxString: String = self.map.exportToGPXString()
            let tmpFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gpx")
            GPXFileManager.saveToURL(tmpFile, gpxContents: gpxString)
            // Add it to the list of tmpFiles.
            // Note: it may add more than once the same file to the list.
            
            // UI code
            DispatchQueue.main.sync {
                // Call Share activity View controller
                let activityViewController = UIActivityViewController(activityItems: [tmpFile], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.shareButton
                activityViewController.popoverPresentationController?.sourceRect = self.shareButton.bounds
                self.present(activityViewController, animated: true, completion: nil)
                self.shouldShowShareActivityIndicator(false)
            }
            
        }
    }
    
    /// Displays spinning activity indicator for share button when true
    func shouldShowShareActivityIndicator(_ isTrue: Bool) {
        // setup
        shareActivityIndicator.color = shareActivityColor
        shareActivityIndicator.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        shareActivityIndicator.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        if isTrue {
            // cross dissolve from button to indicator
            UIView.transition(with: self.shareButton, duration: 0.35, options: [.transitionCrossDissolve], animations: {
                self.shareButton.addSubview(self.shareActivityIndicator)
            }, completion: nil)
            
            shareActivityIndicator.startAnimating()
            shareButton.setImage(nil, for: UIControl.State())
            shareButton.isUserInteractionEnabled = false
        } else {
            // cross dissolve from indicator to button
            UIView.transition(with: self.shareButton, duration: 0.35, options: [.transitionCrossDissolve], animations: {
                self.shareActivityIndicator.removeFromSuperview()
            }, completion: nil)
            
            shareActivityIndicator.stopAnimating()
            shareButton.setImage(UIImage(named: "share"), for: UIControl.State())
            shareButton.isUserInteractionEnabled = true
        }
    }
    
    ///
    /// After invoking this fuction, the map will not be centered on current user position.
    ///
    @objc func stopFollowingUser(_ gesture: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }
    
    ///
    /// UIGestureRecognizerDelegate required for stopFollowingUser
    ///
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
   
    ///
    /// If user long presses the map for a while a Pin (Waypoint/Annotation) will be dropped at that point.
    ///
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if  gesture.state == UIGestureRecognizer.State.began {
            print("Adding Pin map Long Press Gesture")
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            // Allows save and reset
            self.hasWaypoints = true
        }
    }
    
    /// Does nothing in current implementation.
    func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
        print("pinchGesture")
    }
    
    ///
    /// It adds a Pin (Waypoint/Annotation) to current user location.
    ///
    @objc func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map.userLocation.coordinate, altitude: altitude)
        map.addWaypoint(waypoint)
        map.coreDataHelper.add(toCoreData: waypoint)
        self.hasWaypoints = true
    }
    
    ///
    /// Triggered when follow Button is taped.
    ///
    /// Trogles between following or not following the user, that is, automatically centering the map
    ///  in current user´s position.
    ///
    @objc func followButtonTroggler() {
        self.followUser = !self.followUser
    }
    
    ///
    /// Triggered when reset button was tapped.
    ///
    /// It sets map to status .notStarted which clears the map.
    ///
    @objc func resetButtonTapped() {
        
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("SELECT_OPTION", comment: "no comment"), preferredStyle: .actionSheet)

        let continueOption = UIAlertAction(title: NSLocalizedString("CONTINUE_SESSION", comment: "no comment"), style: .default) { _ in
        }

        let cancelOption = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in
        }

        let saveAndStartOption = UIAlertAction(title: NSLocalizedString("SAVE_START_NEW", comment: "no comment"), style: .default) { _ in
            self.saveButtonTapped(withReset: true)
        }

        let deleteOption = UIAlertAction(title: NSLocalizedString("RESET", comment: "no comment"), style: .destructive) { _ in
            self.gpxTrackingStatus = .notStarted
        }

        sheet.addAction(continueOption)
        sheet.addAction(saveAndStartOption)
        sheet.addAction(deleteOption)
        sheet.addAction(cancelOption)
        
        self.present(sheet, animated: true) {
            print("Loaded actionSheet")
        }
    }

    ///
    /// Main Start/Pause Button was tapped.
    ///
    /// It sets the status to tracking or paused.
    ///
    @objc func trackerButtonTapped() {
        print("startGpxTracking::")
        switch gpxTrackingStatus {
        case .notStarted:
            gpxTrackingStatus = .tracking
        case .tracking:
            gpxTrackingStatus = .paused
        case .paused:
            gpxTrackingStatus = .tracking
        }
    }
    
    ///
    /// Triggered when user taps on save Button
    ///
    /// It prompts the user to set a name of the file.
    ///
    @objc func saveButtonTapped(withReset: Bool = false) {
        print("save Button tapped")
        // ignore the save button if there is nothing to save.
        if (gpxTrackingStatus == .notStarted) && !self.hasWaypoints {
            return
        }
        
        // save alert configuration and presentation
        let alertController = UIAlertController(title: NSLocalizedString("SAVE_AS", comment: "no comment"), message: NSLocalizedString("ENTER_SESSION_NAME", comment: "no comment"), preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: { (textField) in
            textField.clearButtonMode = .always
            textField.text = self.lastGpxFilename.isEmpty ? self.defaultFilename() : self.lastGpxFilename
        })
        
        let saveAction = UIAlertAction(title: NSLocalizedString("SAVE", comment: "no comment"), style: .default) { _ in
            let filename = (alertController.textFields?[0].text!.utf16.count == 0) ? self.defaultFilename() : alertController.textFields?[0].text
            print("Save File \(String(describing: filename))")
            // Export to a file
            let gpxString = self.map.exportToGPXString()
            GPXFileManager.save(filename!, gpxContents: gpxString)
            self.lastGpxFilename = filename!
            self.map.coreDataHelper.coreDataDeleteAll(of: CDRoot.self)
            self.map.coreDataHelper.clearAllExceptWaypoints()
            self.map.coreDataHelper.add(toCoreData: filename!, willContinueAfterSave: true)
            if withReset {
                self.gpxTrackingStatus = .notStarted
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
        
    }
    
    ///
    /// There was a memory warning. Right now, it does nothing but to log a line.
    ///
    override func didReceiveMemoryWarning() {
        print("didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///
    /// Checks the location services status
    /// - Are location services enabled (access to location device wide)? If not => displays an alert
    /// - Are location services allowed to this app? If not => displays an alert
    ///
    /// - Seealso: displayLocationServicesDisabledAlert, displayLocationServicesDeniedAlert
    ///
    func checkLocationServicesStatus() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        // Has the user already made a permission choice?
        guard authorizationStatus != .notDetermined else {
            // We should take no action until the user has made a choice
            // Note that we request location permission as part of the property `locationManager` init
            return
        }
        
        // Does the app have permissions to use the location servies?
        guard [.authorizedAlways, .authorizedWhenInUse ].contains(authorizationStatus) else {
            displayLocationServicesDeniedAlert()
            return
        }
        
        // Are location services enabled?
		if authorizationStatus == .denied {
            displayLocationServicesDisabledAlert()
        }
    }
    ///
    /// Displays an alert that informs the user that location services are disabled.
    ///
    /// When location services are disabled is for all applications, not only this one.
    ///
    func displayLocationServicesDisabledAlert() {
        
        let alertController = UIAlertController(title: NSLocalizedString("LOCATION_SERVICES_DISABLED", comment: "no comment"), message: NSLocalizedString("ENABLE_LOCATION_SERVICES", comment: "no comment"), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: NSLocalizedString("SETTINGS", comment: "no comment"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(url)
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)

    }

    ///
    /// Displays an alert that informs the user that access to location was denied for this app (other apps may have access).
    /// It also dispays a button allows the user to go to settings to activate the location.
    ///
    func displayLocationServicesDeniedAlert() {
        if isDisplayingLocationServicesDenied {
            return // display it only once.
        }
        let alertController = UIAlertController(title: NSLocalizedString("ACCESS_TO_LOCATION_DENIED", comment: "no comment"),
                                                message: NSLocalizedString("ALLOW_LOCATION", comment: "no comment"),
                                                preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: NSLocalizedString("SETTINGS", comment: "no comment"),
										   style: .default) { _ in
			if let url = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(url)
			}
		}
		let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL",
                                                                  comment: "no comment"),
                                         style: .cancel) { _ in }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        isDisplayingLocationServicesDenied = true
        present(alertController, animated: true)
    }
    
    /// force dark mode (i.e. white text, if map content is known to be dark)
    func textColorAdaptations() {
        print("-- textColorAdaptation:: Tile server mode: \(self.map.tileServer.colorMode)")
        let colorMode = self.map.tileServer.colorMode
        
        let color: UIColor?
        switch colorMode {
        case .lightMode:
            color = .black
        case .darkMode:
            color = .white
        case .system:
            color = nil
        }
        
        self.signalAccuracyLabel.textColor = color
        self.timeLabel.textColor = color
        self.speedLabel.textColor = color
        self.totalTrackedDistanceLabel.textColor = color
        self.currentSegmentDistanceLabel.textColor = color
        
        // Apply the same forced color behavior to the scale bar
        if let scaleBar = self.map.scaleBar {
            scaleBar.forcedColor = color
        }
    }

}

// MARK: Map Speed Region

extension ViewController {

    func startMapUpdateTimer() {
        mapUpdateTimer?.invalidate()
        mapUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateMapRegionForSpeed()
        }
    }

    func stopMapUpdateTimer() {
        mapUpdateTimer?.invalidate()
        mapUpdateTimer = nil
    }

    /// Start GPS watchdog: controleert elke 10s of er nog locatie-updates binnenkomen.
    /// Als de laatste update meer dan 10s geleden was, herstart de locationManager.
    func startGPSWatchdog() {
        gpsWatchdogTimer?.invalidate()
        gpsWatchdogTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard let last = self.lastGPSUpdateDate else {
                // Nog nooit een update gehad — probeer te starten
                self.locationManager.startUpdatingLocation()
                return
            }
            let elapsed = Date().timeIntervalSince(last)
            if elapsed > 10.0 {
                print("GPS watchdog: geen update sinds \(Int(elapsed))s — GPS fix herstellen")
                self.locationManager.startUpdatingLocation()
                self.locationManager.startUpdatingHeading()
            }
        }
    }

    func stopGPSWatchdog() {
        gpsWatchdogTimer?.invalidate()
        gpsWatchdogTimer = nil
    }

    // MARK: - Waterstand (Rijkswaterstaat DDAPI)

    /// Start waterstand timer — haalt elke 10 minuten verse waterstand op.
    func startWaterstandTimer() {
        fetchWaterstand()
        waterstandTimer?.invalidate()
        waterstandTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in
            self?.fetchWaterstand()
        }
    }

    func stopWaterstandTimer() {
        waterstandTimer?.invalidate()
        waterstandTimer = nil
    }

    /// Haalt actuele waterstand op via Rijkswaterstaat DDAPI.
    /// Meetpunt: IJmuiden (start/finish RHN, Noord-Hollandse kust).
    func fetchWaterstand() {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let begin = formatter.string(from: now.addingTimeInterval(-1800)) // 30 min geleden
        let end   = formatter.string(from: now)

        let url = URL(string: "https://ddapi20-waterwebservices.rijkswaterstaat.nl/ONLINEWAARNEMINGENSERVICES/OphalenWaarnemingen")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("RHNTracker", forHTTPHeaderField: "X-API-KEY")
        let body: [String: Any] = [
            "Locatie": ["Code": "ijmuiden"],
            "AquoPlusWaarnemingMetadata": ["AquoMetadata": [
                "Compartiment": ["Code": "OW"],
                "Grootheid":    ["Code": "WATHTE"]
            ]],
            "Periode": ["Begindatumtijd": begin, "Einddatumtijd": end]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let lijst = json["WaarnemingenLijst"] as? [[String: Any]],
                  let metingen = lijst.first?["MetingenLijst"] as? [[String: Any]],
                  let laatste = metingen.last,
                  let meetwaarde = laatste["Meetwaarde"] as? [String: Any],
                  let waarde = meetwaarde["Waarde_Numeriek"] as? Double else { return }
            let nap = String(format: "%+.0f", waarde)
            DispatchQueue.main.async {
                self.waterInfoLabel.text = "IJmuiden\n\(nap) cm NAP"
            }
        }.resume()
    }

    // MARK: - Weer extra (temp, druk, zicht, golven)

    func fetchExtraWeatherData() {
        let lat = locationManager.location?.coordinate.latitude ?? 52.4630
        let lon = locationManager.location?.coordinate.longitude ?? 4.5480

        // Open-Meteo: temp, zicht, druk (huidig + 3u trend)
        let weatherURL = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,visibility,surface_pressure,cloud_cover&hourly=surface_pressure&past_hours=3&forecast_hours=1&timezone=Europe%2FAmsterdam")!
        URLSession.shared.dataTask(with: weatherURL) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cur = json["current"] as? [String: Any] else { return }
            let temp   = cur["temperature_2m"] as? Double ?? 0
            let feels  = cur["apparent_temperature"] as? Double ?? 0
            let vis    = (cur["visibility"] as? Double ?? 0) / 1000.0
            let press  = cur["surface_pressure"] as? Double ?? 0
            // Luchtdruk trend uit hourly
            var trend = "→"
            if let hourly = json["hourly"] as? [String: Any],
               let pressures = hourly["surface_pressure"] as? [Double], pressures.count >= 3 {
                let diff = pressures.last! - pressures.first!
                trend = diff > 0.5 ? "▲" : diff < -0.5 ? "▼" : "→"
            }
            DispatchQueue.main.async {
                self.tempVisLabel.text = "  \(String(format: "%.1f", temp))° / \(String(format: "%.1f", feels))°\n  \(String(format: "%.1f", vis)) km"
                self.pressureLabel.text = "\(String(format: "%.0f", press)) hPa\n\(trend) \(trend == "▲" ? "stijgend" : trend == "▼" ? "dalend" : "stabiel")"
            }
        }.resume()

        // Open-Meteo Marine: golfhoogte + periode
        let marineURL = URL(string: "https://marine-api.open-meteo.com/v1/marine?latitude=\(lat)&longitude=\(lon)&current=wave_height,wave_period&timezone=Europe%2FAmsterdam")!
        URLSession.shared.dataTask(with: marineURL) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cur = json["current"] as? [String: Any] else { return }
            let waveH = cur["wave_height"] as? Double ?? 0
            let waveP = cur["wave_period"] as? Double ?? 0
            DispatchQueue.main.async {
                self.waveLabel.text = "\(String(format: "%.1f", waveH))m\n\(String(format: "%.1f", waveP))s periode"
            }
        }.resume()
    }

    // MARK: - Radar (Rainviewer)

    // MARK: - Wind (Open-Meteo)

    /// Start wind update timer — haalt elke 5 minuten verse winddata op.
    func startWindTimer() {
        fetchWindData()
        fetchExtraWeatherData()
        windUpdateTimer?.invalidate()
        windUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.fetchWindData()
            self?.fetchExtraWeatherData()
        }
    }

    func stopWindTimer() {
        windUpdateTimer?.invalidate()
        windUpdateTimer = nil
    }

    /// Haalt actuele wind op via Open-Meteo op basis van huidige locatie (of vaste haven als fallback).
    func fetchWindData() {
        let location = locationManager.location?.coordinate
        let lat = location?.latitude ?? 52.4630
        let lon = location?.longitude ?? 4.5480
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=wind_speed_10m,wind_direction_10m,wind_gusts_10m&wind_speed_unit=kn"
        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let speedKn = current["wind_speed_10m"] as? Double,
                  let dirDeg = current["wind_direction_10m"] as? Double else { return }
            let gusts = (current["wind_gusts_10m"] as? Double) ?? 0.0
            let bft = self.knotsToBeaufort(speedKn)
            let arrow = self.windArrow(degrees: dirDeg)
            let gustStr = gusts > 0 ? String(format: " (%.0f)", gusts) : ""
            let subtitle = "\(arrow) Bft \(bft) · \(String(format: "%.1f", speedKn))\(gustStr) kn"
            let coord = self.locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 52.4630, longitude: 4.5480)
            self.lastWindSpeedKn = speedKn
            self.lastWindDirDeg = dirDeg
            DispatchQueue.main.async {
                self.windInfoLabel.attributedText = self.bvkTitleAttributedText(subtitle: subtitle)
                self.map.updateWindAnnotation(coordinate: coord, direction: dirDeg, beaufort: bft, speedKn: speedKn)
                self.updateStromingLabel()
            }
        }.resume()
    }

    /// Berekent windgedreven stroming voor de Noord-Hollandse kust en toont in waveLabel.
    /// Kuststroming ≈ 2% van windsnelheid, richting ≈ windrichting.
    func updateStromingLabel() {
        let stromingKn = lastWindSpeedKn * 0.02
        let arrow = windArrow(degrees: lastWindDirDeg)
        let waveText = waveLabel.text?.components(separatedBy: "\n").first ?? "--"
        waveLabel.text = "\(waveText)\n\(arrow) \(String(format: "%.2f", stromingKn)) kn stroom"
    }

    /// Maakt NSAttributedString met "RHN GPX TRACKER" in geel en subtitle in wit.
    func bvkTitleAttributedText(subtitle: String) -> NSAttributedString {
        let font = UIFont(name: "DinAlternate-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16)
        let title = NSMutableAttributedString(string: "RHN GPX TRACKER\n",
            attributes: [.foregroundColor: UIColor.yellow, .font: font])
        title.append(NSAttributedString(string: subtitle,
            attributes: [.foregroundColor: UIColor.white, .font: font]))
        return title
    }

    /// Converteert knopen naar Beaufort-schaal.
    func knotsToBeaufort(_ knots: Double) -> Int {
        switch knots {
        case ..<1:    return 0
        case ..<4:    return 1
        case ..<7:    return 2
        case ..<11:   return 3
        case ..<17:   return 4
        case ..<22:   return 5
        case ..<28:   return 6
        case ..<34:   return 7
        case ..<41:   return 8
        case ..<48:   return 9
        case ..<56:   return 10
        case ..<64:   return 11
        default:      return 12
        }
    }

    /// Geeft een richtingspijl terug op basis van graden (vanwaar de wind komt).
    func windArrow(degrees: Double) -> String {
        let dirs = ["↓","↙","←","↖","↑","↗","→","↘"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return dirs[index]
    }

    /// Adjusts the visible map region based on the average speed over the last 60 seconds.
    /// Runs independently of the GPX recording interval so tiles always preload ahead.
    ///
    /// Speed thresholds (knots → latitudeDelta):
    ///   < 0.5 kn  → 0.002° (~220 m)  anchored
    ///   0.5–2 kn  → 0.005° (~555 m)  slow
    ///   2–5 kn    → 0.010° (~1.1 km) moderate
    ///   5–8 kn    → 0.018° (~2.0 km) fast
    ///   8+ kn     → 0.030° (~3.3 km) very fast
    func updateMapRegionForSpeed() {
        guard followUser else { return }

        let now = Date()
        speedReadings = speedReadings.filter { now.timeIntervalSince($0.date) <= 60.0 }

        let avgSpeedMs: Double = speedReadings.isEmpty
            ? 0
            : speedReadings.map(\.speedMs).reduce(0, +) / Double(speedReadings.count)

        let avgKnots = avgSpeedMs * 1.94384

        let targetSpan: CLLocationDegrees
        switch avgKnots {
        case ..<0.5:  targetSpan = 0.002
        case 0.5..<2: targetSpan = 0.005
        case 2..<5:   targetSpan = 0.010
        case 5..<8:   targetSpan = 0.018
        default:      targetSpan = 0.030
        }

        let currentSpan = map.region.span.latitudeDelta
        guard abs(currentSpan - targetSpan) / max(currentSpan, 0.001) > 0.20 else { return }

        let newRegion = MKCoordinateRegion(
            center: map.userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: targetSpan, longitudeDelta: targetSpan)
        )
        map.setRegion(newRegion, animated: true)
    }
}

// MARK: StopWatchDelegate

///
/// Updates the `timeLabel` with the `stopWatch` elapsedTime.
/// In the main ViewController there is a label that holds the elapsed time, that is, the time that
/// user has been tracking his position.
///
///
extension ViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = elapsedTimeString
    }
}

// MARK: PreferencesTableViewControllerDelegate

extension ViewController: PreferencesTableViewControllerDelegate {
    
    /// Update the activity type that the location manager is using.
    ///
    /// When user changes the activity type in preferences, this function is invoked to update the activity type of the location manager.
    ///
    func didUpdateActivityType(_ newActivityType: Int) {
        print("PreferencesTableViewControllerDelegate:: didUpdateActivityType: \(newActivityType)")
        self.locationManager.activityType = CLActivityType(rawValue: newActivityType)!
    }
    
    ///
    /// Updates the `tileServer` the map is using.
    ///
    /// If user enters preferences and he changes his preferences regarding the `tileServer`,
    /// the map of the main `ViewController` needs to be aware of it.
    ///
    /// `PreferencesTableViewController` informs the main `ViewController` through this delegate.
    ///
    func didUpdateTileServer(_ newGpxTileServer: Int) {
        print("PreferencesTableViewControllerDelegate:: didUpdateTileServer: \(newGpxTileServer)")
        let newTileServer = GPXTileServer(rawValue: newGpxTileServer)!
        self.map.tileServer = newTileServer
        self.textColorAdaptations()
    }
    
    ///
    /// If user changed the setting of using cache, through this delegate, the main `ViewController`
    /// informs the map to behave accordingly.
    ///
    func didUpdateUseCache(_ newUseCache: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateUseCache: \(newUseCache)")
        self.map.useCache = newUseCache
    }
    
    // User changed the setting of use imperial units.
    func didUpdateUseImperial(_ newUseImperial: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateUseImperial: \(newUseImperial)")
        useImperial = newUseImperial
        totalTrackedDistanceLabel.useImperial = useImperial
        currentSegmentDistanceLabel.useImperial = useImperial
        // Because we dont know if last speed was unknown we set it as unknown.
        // In regular circunstances it will go to the new units relatively fast.
        speedLabel.text = kUnknownSpeedText
        signalAccuracyLabel.text = kUnknownAccuracyText
        
        //Update the Scale Bar units
        map.scaleBar?.useImperial = useImperial
        
    }
    
    func didUpdateShowScaleBar(_ newShowScaleBar: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateShowScaleBar: \(newShowScaleBar)")
        self.scaleBar.isHidden = !newShowScaleBar
    }
    
    // User changed the setting of use imperial units.
    func didUpdateKeepScreenAlwaysOn(_ newKeepScreenAlwaysOn: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateKeepScreenAlwaysOn: \(newKeepScreenAlwaysOn)")
        UIApplication.shared.isIdleTimerDisabled = newKeepScreenAlwaysOn
    }

    func didUpdateTrackInterval(_ newIntervalSeconds: Double) {
        print("PreferencesTableViewControllerDelegate:: didUpdateTrackInterval: \(newIntervalSeconds)s")
        lastTrackedDate = nil
    }

    func didUpdateChargerMode(_ newChargerMode: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateChargerMode: \(newChargerMode)")
        if newChargerMode {
            // Charger mode: altijd hoogste nauwkeurigheid, geen snelheidsgebaseerde aanpassing
            currentGPSProfile = "" // reset zodat volgende update opnieuw evalueert
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter  = 2
        } else {
            // Terug naar adaptief: reset profiel zodat het direct bijstelt bij volgende locatie-update
            currentGPSProfile = ""
        }
    }

    func didUpdateShowWindOverlay(_ newValue: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateShowWindOverlay: \(newValue)")
        map.showWindOverlay = newValue
    }

    func didUpdateShowOWMOverlay(_ newValue: Bool, layer: OWMLayer) {
        Preferences.shared.owmLayer = layer
        if newValue {
            map.showOWMOverlay = false   // reset zodat didSet altijd vuurt
            map.showOWMOverlay = true
            Toast.regular("OWM: \(layer.displayName) actief", position: .top)
        } else {
            map.showOWMOverlay = false
            Toast.regular("OWM kaartlaag uit", position: .top)
        }
    }

    /// Pas GPS-accuraatheid en distanceFilter aan op basis van snelheid.
    /// Dit bespaart 60-80% batterij bij stilliggen of langzaam varen.
    ///
    /// Profielen (snelheid in knopen):
    ///   < 0.5 kn  → HundredMeters  + 50m filter  (GPS-chip uit, cel/wifi)
    ///   0.5–2 kn  → TenMeters      + 10m filter  (GPS-chip aan, minder agressief)
    ///   2–6 kn    → Best           +  5m filter  (volle GPS)
    ///   > 6 kn    → Best           +  2m filter  (volle GPS, max resolutie)
    private func updateGPSAccuracy(speedMs: Double) {
        // Charger mode: altijd best, geen aanpassing nodig
        guard !Preferences.shared.chargerMode else { return }

        let knots = speedMs * 1.94384

        let accuracy: CLLocationAccuracy
        let filter: CLLocationDistance
        let profile: String

        switch knots {
        case ..<0.5:
            accuracy = kCLLocationAccuracyHundredMeters
            filter   = 50
            profile  = "stilliggend (<0.5kn) → 100m/50m"
        case 0.5..<2.0:
            accuracy = kCLLocationAccuracyNearestTenMeters
            filter   = 10
            profile  = "langzaam (0.5–2kn) → 10m/10m"
        case 2.0..<6.0:
            accuracy = kCLLocationAccuracyBest
            filter   = 5
            profile  = "varend (2–6kn) → best/5m"
        default:
            accuracy = kCLLocationAccuracyBest
            filter   = 2
            profile  = "snel (>6kn) → best/2m"
        }

        // Alleen updaten als het profiel veranderd is (voorkomt onnodige CLLocationManager-aanroepen)
        if profile != currentGPSProfile {
            currentGPSProfile = profile
            locationManager.desiredAccuracy = accuracy
            locationManager.distanceFilter  = filter
            print("GPS profiel: \(profile)")
        }
    }
}

/// Extends `ViewController`` to support `GPXFilesTableViewControllerDelegate` function
/// that loads into the map a the file selected by the user.
extension ViewController: GPXFilesTableViewControllerDelegate {
    ///
    /// Loads the selected GPX File into the map.
    ///
    /// Resets whatever estatus was before.
    ///
    func didLoadGPXFileWithName(_ gpxFilename: String, gpxRoot: GPXRoot) {
        // Emulate a reset button tap
        self.resetButtonTapped()
        // println("Loaded GPX file", gpx.gpx())
        lastGpxFilename = gpxFilename
        // Adds last file name to core data as well
        self.map.coreDataHelper.add(toCoreData: gpxFilename, willContinueAfterSave: false)
        // Force reset timer just in case reset does not do it
        self.stopWatch.reset()
        // Load data
        self.map.importFromGPXRoot(gpxRoot)
        // Stop following user
        self.followUser = false
        // Center map in GPX data
        self.map.regionToGPXExtent()
        self.gpxTrackingStatus = .paused
        
        self.totalTrackedDistanceLabel.distance = self.map.session.totalTrackedDistance
        
    }
}

// MARK: CLLocationManagerDelegate

// Extends view controller to support Location Manager delegate protocol
extension ViewController: CLLocationManagerDelegate {

    /// Location manager calls this func to inform there was an error.
    ///
    /// It performs the following actions:
    ///  - Sets coordsLabel with `kNotGettingLocationText`, signal accuracy to
    ///    kUnknownAccuracyText and signalImageView to signalImage0.
    ///  - If the error code is `CLError.denied` it calls `checkLocationServicesStatus`
    
    ///
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        coordsLabel.text = kNotGettingLocationText
        signalAccuracyLabel.text = kUnknownAccuracyText
        signalImageView.image = signalImage0
        let locationError = error as? CLError
        switch locationError?.code {
        case CLError.locationUnknown:
            // iOS geeft dit als GPS tijdelijk niet beschikbaar is (bijv. andere app heeft prioriteit).
            // Herstart location updates na korte delay om de fix te herstellen.
            print("Location Unknown — GPS fix herstellen over 2s")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.locationManager.startUpdatingLocation()
                self.locationManager.startUpdatingHeading()
            }
        case CLError.denied:
            print("Access to location services denied. Display message")
            checkLocationServicesStatus()
        case CLError.headingFailure:
            print("Heading failure")
        default:
            print("Default error")
        }

    }
    
    ///
    /// Updates location accuracy and map information when user is in a new position
    ///
    ///
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Registreer tijdstip voor GPS watchdog
        lastGPSUpdateDate = Date()

        // Update signal image accuracy
        let newLocation = locations.first!

        // Verplaats windpijl mee met GPS positie
        if map.showWindOverlay, let wind = map.windAnnotation {
            wind.coordinate = newLocation.coordinate
        }

        if newLocation.speed >= 0 {
            speedReadings.append((date: Date(), speedMs: newLocation.speed))
            // Pas GPS-accuraatheid aan op snelheid (batterijbesparing)
            updateGPSAccuracy(speedMs: newLocation.speed)
        }
        // Update horizontal accuracy
        let hAcc = newLocation.horizontalAccuracy
        signalAccuracyLabel.text =  hAcc.toAccuracy(useImperial: useImperial)
        if hAcc < kSignalAccuracy6 {
            self.signalImageView.image = signalImage6
        } else if hAcc < kSignalAccuracy5 {
            self.signalImageView.image = signalImage5
        } else if hAcc < kSignalAccuracy4 {
            self.signalImageView.image = signalImage4
        } else if hAcc < kSignalAccuracy3 {
            self.signalImageView.image = signalImage3
        } else if hAcc < kSignalAccuracy2 {
            self.signalImageView.image = signalImage2
        } else if hAcc < kSignalAccuracy1 {
            self.signalImageView.image = signalImage1
        } else {
            self.signalImageView.image = signalImage0
        }
        
        // Update coordsLabel
        let latFormat = String(format: "%.6f", newLocation.coordinate.latitude)
        let lonFormat = String(format: "%.6f", newLocation.coordinate.longitude)
        let altitude = newLocation.altitude.toAltitude(useImperial: useImperial)
        let knots = newLocation.speed >= 0 ? String(format: "%.1f kn", newLocation.speed * 1.94384) : "·.· kn"
        coordsLabel.text = "  Lat  \(latFormat)\n  Lon  \(lonFormat)"
        
        // Update speed
        speedLabel.text = (newLocation.speed < 0) ? kUnknownSpeedText : newLocation.speed.toSpeed(useImperial: useImperial)
        
        // Update Map center and track overlay if user is being followed
        if followUser {
            map.setCenter(newLocation.coordinate, animated: true)
        }
        if gpxTrackingStatus == .tracking {
            let now = Date()
            let interval = Preferences.shared.trackIntervalSeconds
            if lastTrackedDate == nil || now.timeIntervalSince(lastTrackedDate!) >= interval {
                lastTrackedDate = now
                print("didUpdateLocation: adding point to track (\(newLocation.coordinate.latitude),\(newLocation.coordinate.longitude))")
                map.addPointToCurrentTrackSegmentAtLocation(newLocation)
                totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
                currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
            }
        }
    }

    ///
    ///
    /// When there is a change on the heading (direction in which the device oriented) it makes a request to the map
    /// to updathe the heading indicator (a small arrow next to user location point)
    ///
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("ViewController::didUpdateHeading true: \(newHeading.trueHeading) magnetic: \(newHeading.magneticHeading)")
        print("mkMapcamera heading=\(map.camera.heading)")
        map.heading = newHeading // updates heading variable
        map.updateHeading() // updates heading view's rotation

        // Course-up: draai de kaartcamera mee met rijrichting als followUser actief is
        let trueHeading = newHeading.trueHeading
        guard trueHeading >= 0, followUser else { return }
        lastTrueHeading = trueHeading
        let camera = map.camera
        camera.heading = trueHeading
        map.setCamera(camera, animated: true)
    }
    
    ///
    /// Called by the system when `CLLocationManager` is created and when the user makes a permission choice
    ///
    /// We handle this delegate callback so that we can check if the user has allowed location access, else we show a warning
    ///
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationServicesStatus()
    }

    /// iOS kan locatie-updates intern pauzeren (bijv. andere GPS-app op voorgrond, signaalverlies).
    /// Herstart de updates automatisch na 2 seconden zodat de GPS fix hersteld wordt.
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("GPS watchdog: locationManager gepauzeerd — GPS fix herstellen over 2s")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
    }
}

extension Notification.Name {
    static let loadRecoveredFile = Notification.Name("loadRecoveredFile")
    static let updateAppearance = Notification.Name("updateAppearance")
    // swiftlint:disable file_length
}

// swiftlint:enable line_length

