//
//  ParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/6/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/**
 A Parse Framework Installation Object that is a local representation of an
 installation persisted to the Parse cloud. This class is a subclass of a
 `ParseObject`, and retains the same functionality of a ParseObject, but also extends
 it with installation-specific fields and related immutability and validity
 checks.
 
 A valid `ParseInstallation` can only be instantiated via
 `+currentInstallation` because the required identifier fields
 are readonly. The `timeZone` and `badge` fields are also readonly properties which
 are automatically updated to match the device's time zone and application badge
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.
 
 `ParseInstallation` objects which have a valid `deviceToken` and are saved to
 the Parse cloud can be used to target push notifications.
*/
public protocol ParseInstallation: ParseObject {

    /**
    The device type for the `ParseInstallation`.
    */
    var deviceType: String? { get set }

    /**
    The installationId for the `ParseInstallation`.
    */
    var installationId: String? { get set }

    /**
    The device token for the `ParseInstallation`.
    */
    var deviceToken: String? { get set }

    /**
    The badge for the `ParseInstallation`.
    */
    var badge: Int? { get set }

    /**
    The name of the time zone for the `ParseInstallation`.
    */
    var timeZone: String? { get set }

    /**
    The channels for the `ParseInstallation`.
    */
    var channels: [String]? { get set }

    var appName: String? { get set }

    var appIdentifier: String? { get set }

    var appVersion: String? { get set }

    var parseVersion: String? { get set }

    var localeIdentifier: String? { get set }
}

// MARK: Default Implementations
public extension ParseInstallation {
    static var className: String {
        return "_Installation"
    }
}

// MARK: CurrentInstallationContainer
struct CurrentInstallationContainer<T: ParseInstallation>: Codable {
    var currentInstallation: T?
    var installationId: String?
}

// MARK: Current Installation Support
extension ParseInstallation {
    static var currentInstallationContainer: CurrentInstallationContainer<Self>? {
        get { try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) }
        set {
            guard var newInstallation = newValue else {
                return
            }
            if newInstallation.installationId == nil {
                let newInstallationId = UUID().uuidString.lowercased()
                newInstallation.installationId = newInstallationId
                newInstallation.currentInstallation?.createInstallationId(newId: newInstallationId)
            } else {
                if newInstallation.currentInstallation?.installationId != newInstallation.installationId! {
                    //If the user made changes, set back to the original
                    newInstallation.currentInstallation?.installationId = newInstallation.installationId!
                }
            }
            //Always pull automatic info to ensure user made no changes
            newInstallation.currentInstallation?.updateAutomaticInfo()

            try? KeychainStore.shared.set(newInstallation, for: ParseStorage.Keys.currentInstallation)
        }
    }

    /**
     Gets the currently logged in user from disk and returns an instance of it.
     
     - returns: Returns a `ParseUser` that is the currently logged in user. If there is none, returns `nil`.
    */
    public static var current: Self? {
        get { Self.currentInstallationContainer?.currentInstallation }
        set { Self.currentInstallationContainer?.currentInstallation = newValue }
    }

    /**
     The session token for the `ParseUser`.
     
     This is set by the server upon successful authentication.
    */
    public var installationId: String? {
        Self.currentInstallationContainer?.installationId
    }
}

// MARK: Automatic Info
extension ParseInstallation {
    mutating func updateAutomaticInfo() {
        updateTimeZoneFromDevice()
        updateBadgeFromDevice()
        updateVersionInfoFromDevice()
        updateLocaleIdentifierFromDevice()
    }

    mutating func createInstallationId(newId: String) {
        if installationId == nil {
            installationId = newId
        }
    }

    mutating func updateTimeZoneFromDevice() {
        let currentTimeZone = TimeZone.current.identifier
        if timeZone != currentTimeZone {
            timeZone = currentTimeZone
        }
    }

    mutating func updateBadgeFromDevice() {
        let applicationBadge: Int!
        #if canImport(UIKit)
            applicationBadge = UIApplication.shared.applicationIconBadgeNumber
        #else
            guard let currentApplicationBadge = NSApplication.shared.dockTile.badgeLabel else {
                return
            }
            applicationBadge = Int(currentApplicationBadge)
        #endif

        if badge != applicationBadge {
            badge = applicationBadge
        }
    }

    mutating func updateVersionInfoFromDevice() {
        guard let appInfo = Bundle.main.infoDictionary else {
            return
        }

        #if TARGET_OS_MACCATALYST
        // If using an Xcode new enough to know about Mac Catalyst:
        // Mac Catalyst Apps use a prefix to the bundle ID. This should not be transmitted
        // to the parse backend. Catalyst apps should look like iOS apps otherwise
        // push and other services don't work properly.
        if let currentAppIdentifier = appInfo[String(kCFBundleIdentifierKey)] as? String {
            let macCatalystBundleIdPrefix = "maccatalyst."
            if currentAppIdentifier.hasPrefix(macCatalystBundleIdPrefix) {
                appIdentifier = currentAppIdentifier.replacingOccurrences(of: macCatalystBundleIdPrefix, with: "")
            }
        }

        #else
        if let currentAppIdentifier = appInfo[String(kCFBundleIdentifierKey)] as? String {
            if appIdentifier != currentAppIdentifier {
                appIdentifier = currentAppIdentifier
            }
        }
        #endif

        if let currentAppName = appInfo[String(kCFBundleNameKey)] as? String {
            if appName != currentAppName {
                appName = currentAppName
            }
        }

        if let currentAppVersion = appInfo[String(kCFBundleVersionKey)] as? String {
            if appVersion != currentAppVersion {
                appVersion = currentAppVersion
            }
        }

        if parseVersion != kParseVersion {
            parseVersion = kParseVersion
        }
    }

    /**
     Save localeIdentifier in the following format: [language code]-[COUNTRY CODE].
     
     The language codes are two-letter lowercase ISO language codes (such as "en") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_639-1">ISO 639-1</a>.
     The country codes are two-letter uppercase ISO country codes (such as "US") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3">ISO 3166-1</a>.
    
     Many iOS locale identifiers don't contain the country code -> inconsistencies with Android/Windows Phone.
    */
    mutating func updateLocaleIdentifierFromDevice() {
        guard let language = Locale.current.languageCode else {
            return
        }

        let currentLocalIdentifier: String!
        if let regionCode = Locale.current.regionCode {
            currentLocalIdentifier = "\(language)-\(regionCode)"
        } else {
            currentLocalIdentifier = language
        }

        if localeIdentifier != currentLocalIdentifier {
            localeIdentifier = currentLocalIdentifier
        }
    }
}
