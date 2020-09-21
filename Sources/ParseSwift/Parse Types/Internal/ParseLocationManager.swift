//
//  ParseLocationManager.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/21/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

/**
 ParseLocationManager is an internal class which wraps a CLLocationManager and
 returns an updated CLLocation via the provided block.
 When -addCurrentLocation is called, the CLLocationManager's
 -startUpdatingLocations is called, and upon CLLocationManagerDelegate callback
 (either success or failure), any handlers that were passed to this class will
 be called _once_ with the updated location, then removed. The CLLocationManager
 stopsUpdatingLocation upon a single failure or success case, so that the next
 location request is guaranteed a speedily returned CLLocation.
 */
class ParseLocationMananger: NSObject {
    let locationManager: CLLocationManager
    let bundle: Bundle
    var lastLocation: CLLocation?

    convenience override init() {
        self.init(locationManager: CLLocationManager(), bundle: Bundle.main)
    }

    convenience init(locationManager: CLLocationManager) {
        self.init(locationManager: locationManager, bundle: Bundle.main)
    }

    init(locationManager: CLLocationManager, bundle: Bundle) {
        self.locationManager = locationManager
        self.bundle = bundle
        super.init()
        locationManager.delegate = self
    }

    func addCurrentLocation() {
    #if os(watchOS)
        if self.bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil {
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            self.locationManager.requestAlwaysAuthorization()
        }
        self.locationManager.requestLocation()
    #elseif os(tvOS)
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestLocation()
    #elseif os(iOS)
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background &&
                self.bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil {
                self.locationManager.requestWhenInUseAuthorization()
            } else {
                self.locationManager.requestAlwaysAuthorization()
            }
            self.locationManager.startUpdatingLocation()
        }
    #elseif os (macOS)
        self.locationManager.startUpdatingLocation()
    #endif
    }

    deinit {
        self.locationManager.delegate = nil
    }
}

extension ParseLocationMananger: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        lastLocation = nil
    }
}
