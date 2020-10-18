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
#elseif canImport(AppKit)
import AppKit
#endif

/**
 Objects that conform to the `ParseInstallation` protocol have a local representation of an
 installation persisted to the Parse cloud. This protocol inherits from the
 `ParseObject` protocol, and retains the same functionality of a `ParseObject`, but also extends
 it with installation-specific fields and related immutability and validity
 checks.

 A valid `ParseInstallation` can only be instantiated via
 `+current` because the required identifier fields
 are readonly. The `timeZone` and `badge` fields are also readonly properties which
 are automatically updated to match the device's time zone and application badge
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.

 `ParseInstallation` objects which have a valid `deviceToken` and are saved to
 the Parse cloud can be used to target push notifications.

 - warning: Only use `ParseInstallation` objects on the main thread as they
   require UIApplication for `badge`
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
    static var currentInstallationContainer: CurrentInstallationContainer<Self> {
        get {
            guard let installationInMemory: CurrentInstallationContainer<Self> =
                try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    guard let installationFromKeyChain: CurrentInstallationContainer<Self> =
                        try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                         else {
                            var newInstallation = CurrentInstallationContainer<Self>()
                            let newInstallationId = UUID().uuidString.lowercased()
                            newInstallation.installationId = newInstallationId
                            newInstallation.currentInstallation?.createInstallationId(newId: newInstallationId)
                            newInstallation.currentInstallation?.updateAutomaticInfo()
                            try? KeychainStore.shared.set(newInstallation, for: ParseStorage.Keys.currentInstallation)
                            try? ParseStorage.shared.set(newInstallation, for: ParseStorage.Keys.currentInstallation)
                        return newInstallation
                    }
                    return installationFromKeyChain
            }
            return installationInMemory
        }
        set {
            try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentInstallation)
        }
    }

    internal static func updateInternalFieldsCorrectly() {
        if Self.currentInstallationContainer.currentInstallation?.installationId !=
            Self.currentInstallationContainer.installationId! {
            //If the user made changes, set back to the original
            Self.currentInstallationContainer.currentInstallation?.installationId =
                Self.currentInstallationContainer.installationId!
        }
        //Always pull automatic info to ensure user made no changes to immutable values
        Self.currentInstallationContainer.currentInstallation?.updateAutomaticInfo()
    }

    internal static func saveCurrentContainerToKeychain() {
        //Only save the BaseParseInstallation to keep Keychain footprint finite
        guard let currentInstallationInMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            return
        }
        try? KeychainStore.shared.set(currentInstallationInMemory, for: ParseStorage.Keys.currentInstallation)
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
    }

    /**
     Gets/Sets properties of the current installation in the Keychain.

     - returns: Returns a `ParseInstallation` that is the current device. If there is none, returns `nil`.
    */
    public static var current: Self? {
        get {
            Self.currentInstallationContainer.currentInstallation?.updateBadgeFromDevice()
            return Self.currentInstallationContainer.currentInstallation
        }
        set {
            Self.currentInstallationContainer.currentInstallation = newValue
            Self.updateInternalFieldsCorrectly()
        }
    }
}

// MARK: Automatic Info
extension ParseInstallation {
    mutating func updateAutomaticInfo() {
        updateDeviceTypeFromDevice()
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

    mutating func updateDeviceTypeFromDevice() {

        if deviceType != ParseConstants.deviceType {
            deviceType = ParseConstants.deviceType
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

        #if canImport(UIKit) && !os(watchOS)
        applicationBadge = UIApplication.shared.applicationIconBadgeNumber
        #elseif canImport(AppKit)
        guard let currentApplicationBadge = NSApplication.shared.dockTile.badgeLabel else {
            //If badgeLabel not set, assume it's 0
            applicationBadge = 0
            return
        }
        applicationBadge = Int(currentApplicationBadge)
        #else
        applicationBadge = 0
        #endif

        if badge != applicationBadge {
            badge = applicationBadge
            //Since this changes, update the Keychain whenever it changes
            Self.saveCurrentContainerToKeychain()
        }
    }

    mutating func updateVersionInfoFromDevice() {
        guard let appInfo = Bundle.main.infoDictionary else {
            return
        }

        #if !os(Linux)
        #if TARGET_OS_MACCATALYST
        // If using an Xcode new enough to know about Mac Catalyst:
        // Mac Catalyst Apps use a prefix to the bundle ID. This should not be transmitted
        // to Parse Server. Catalyst apps should look like iOS apps otherwise
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
        #endif

        if parseVersion != ParseConstants.parseVersion {
            parseVersion = ParseConstants.parseVersion
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
