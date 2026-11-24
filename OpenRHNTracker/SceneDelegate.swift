//
//  SceneDelegate.swift
//  OpenRHNTracker
//
//  Nieuwste iOS start een app zonder scene-levenscyclus niet meer
//  (UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption → crash bij opstarten).
//  Het venster komt uit Main.storyboard via UIApplicationSceneManifest in Info.plist.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// GPX-bestand dat de app opende terwijl hij nog niet draaide.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        connectionOptions.urlContexts.forEach { AppDelegate.importGPX(from: $0.url) }
    }

    /// GPX-bestand geopend ("Openen met RNH Tracker") terwijl de app al draait.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { AppDelegate.importGPX(from: $0.url) }
    }
}
