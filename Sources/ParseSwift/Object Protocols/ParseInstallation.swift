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

// MARK: Fetchable
extension ParseInstallation {
    internal static func updateKeychainIfNeeded(_ results: [Self], deleting: Bool = false) throws {
        guard BaseParseUser.current != nil,
              let currentInstallation = BaseParseInstallation.current else {
            return
        }

        var saveInstallation: Self?
        let foundCurrentInstallationObjects = results.filter { $0.hasSameObjectId(as: currentInstallation) }
        if let foundCurrentInstallation = foundCurrentInstallationObjects.first {
            saveInstallation = foundCurrentInstallation
        } else {
            saveInstallation = results.first
        }

        if saveInstallation != nil {
            if !deleting {
                Self.current = saveInstallation
                Self.saveCurrentContainerToKeychain()
            } else {
                Self.deleteCurrentContainerFromKeychain()
            }
        }
    }

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        let result: Self = try fetchCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                if case .success(let foundResult) = result {
                    try? Self.updateKeychainIfNeeded([foundResult])
                }
                completion(result)
            }
         } catch let error as ParseError {
             completion(.failure(error))
         } catch {
             completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
         }
    }
}

// MARK: Saveable
extension ParseInstallation {

    /**
     Saves the `ParseObject` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: A Error of type `ParseError`.

     - returns: Returns saved `ParseObject`.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [NSDictionary: PointerType]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                childObjects = savedChildObjects
                group.leave()
            case .failure(let parseError):
                error = parseError
            }
        }
        group.wait()

        if let error = error {
            throw error
        }

        let result: Self = try saveCommand().execute(options: options, childObjects: childObjects)
        try? Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { result in
            switch result {

            case .success(let savedChildObjects):
                self.saveCommand().executeAsync(options: options, callbackQueue: callbackQueue,
                                           childObjects: savedChildObjects) { result in
                    if case .success(let foundResults) = result {
                        try? Self.updateKeychainIfNeeded([foundResults])
                    }
                    completion(result)
                }
            case .failure(let parseError):
                completion(.failure(parseError))
            }
        }
    }
}

// MARK: Deletable
extension ParseInstallation {
    /**
     Deletes the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - throws: An Error of `ParseError` type.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
        try? Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (ParseError?) -> Void
    ) {
         do {
            try deleteCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success:
                    try? Self.updateKeychainIfNeeded([self], deleting: true)
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
            }
         } catch let error as ParseError {
             completion(error)
         } catch {
             completion(ParseError(code: .unknownError, message: error.localizedDescription))
         }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {

    /**
     Saves a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to save objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
    */
    func saveAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let commands = map { $0.saveCommand() }
        let returnResults = try API.Command<Self.Element, Self.Element>
            .batch(commands: commands)
            .execute(options: options)
        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnResults
    }

    /**
     Saves a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to save objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
    */
    func saveAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let commands = map { $0.saveCommand() }
        API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
            .executeAsync(options: options, callbackQueue: callbackQueue) { results in
                switch results {

                case .success(let saved):
                    try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
                    completion(.success(saved))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    /**
     Fetches a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to fetch objects. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            let fetchedObjects = try query.find(options: options)
            var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

            uniqueObjectIds.forEach {
                let uniqueObjectId = $0
                if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                    fetchedObjectsToReturn.append(.success(fetchedObject))
                } else {
                    fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                      // swiftlint:disable:next line_length
                                                                      message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                }
            }
            try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to fetch objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: The order in which objects are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            query.find(options: options, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let fetchedObjects):
                    var fetchedObjectsToReturn = [(Result<Self.Element, ParseError>)]()

                    uniqueObjectIds.forEach {
                        let uniqueObjectId = $0
                        if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
                            fetchedObjectsToReturn.append(.success(fetchedObject))
                        } else {
                            fetchedObjectsToReturn.append(.failure(ParseError(code: .objectNotFound,
                                                                              // swiftlint:disable:next line_length
                                                                              message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\"")))
                        }
                    }
                    try? Self.Element.updateKeychainIfNeeded(fetchedObjects)
                    completion(.success(fetchedObjectsToReturn))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            completion(.failure(ParseError(code: .unknownError,
                                           message: "all items to fetch must be of the same class")))
        }
    }

    /**
     Deletes a collection of objects *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of options used to delete objects. Defaults to an empty set.

     - returns: Returns a Result enum with `true` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: `ParseError`
    */
    func deleteAll(options: API.Options = []) throws -> [(Result<Bool, ParseError>)] {
        let commands = try map { try $0.deleteCommand() }
        let returnResults = try API.Command<Self.Element, Self.Element>
            .batch(commands: commands)
            .execute(options: options)

        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnResults
    }

    /**
     Deletes a collection of objects all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of options used to delete objects. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Bool, ParseError>)], ParseError>)`.
     Each element in the array is a Result enum with `true` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
    */
    func deleteAll(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Bool, ParseError>)], ParseError>) -> Void
    ) {
        do {
            let commands = try map({ try $0.deleteCommand() })
            API.Command<Self.Element, Self.Element>
                    .batch(commands: commands)
                .executeAsync(options: options, callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let deleted):
                        try? Self.Element.updateKeychainIfNeeded(compactMap {$0})
                        completion(.success(deleted))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        } catch {
            guard let parseError = error as? ParseError else {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
                return
            }
            completion(.failure(parseError))
        }
    }
} // swiftlint:disable:this file_length
