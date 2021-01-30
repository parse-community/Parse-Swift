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
 *current* because the required identifier fields
 are readonly. The `timeZone` and `badge` fields are also readonly properties which
 are automatically updated to match the device's time zone and application badge
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.

 `ParseInstallation` installations which have a valid `deviceToken` and are saved to
 the Parse cloud can be used to target push notifications.

 - warning: Only use `ParseInstallation.current` installations on the main thread as they
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
        "_Installation"
    }
}

// MARK: Convenience
extension ParseInstallation {
    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .installation(objectId: objectId)
        }

        return .installations
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
                #if !os(Linux)
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
                #else
                    var newInstallation = CurrentInstallationContainer<Self>()
                    let newInstallationId = UUID().uuidString.lowercased()
                    newInstallation.installationId = newInstallationId
                    newInstallation.currentInstallation?.createInstallationId(newId: newInstallationId)
                    newInstallation.currentInstallation?.updateAutomaticInfo()
                    try? ParseStorage.shared.set(newInstallation, for: ParseStorage.Keys.currentInstallation)
                    return newInstallation
                #endif
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
        #if !os(Linux)
        try? KeychainStore.shared.set(currentInstallationInMemory, for: ParseStorage.Keys.currentInstallation)
        #endif
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #if !os(Linux)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #endif
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
    internal static func updateKeychainIfNeeded(_ results: [Self], deleting: Bool = false) {
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
     Fetches the `ParseInstallation` *synchronously* with the current data from the server
     and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        let result: Self = try fetchCommand()
            .execute(options: options, callbackQueue: .main)
        Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    public func fetch(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
         do {
            try fetchCommand()
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    callbackQueue.async {
                        if case .success(let foundResult) = result {
                            Self.updateKeychainIfNeeded([foundResult])
                        }
                        completion(result)
                    }
                }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    func fetchCommand() throws -> API.Command<Self, Self> {
        guard isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot fetch an object without id")
        }

        return API.Command(method: .GET,
                    path: endpoint) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseInstallation {

    /**
     Saves the `ParseInstallation` *synchronously* and throws an error if there's an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseInstallation`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    public func save(options: API.Options = []) throws -> Self {
        var childObjects: [String: PointerType]?
        var childFiles: [UUID: ParseFile]?
        var error: ParseError?
        let group = DispatchGroup()
        group.enter()
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) in
            childObjects = savedChildObjects
            childFiles = savedChildFiles
            error = parseError
            group.leave()
        }
        group.wait()

        if let error = error {
            throw error
        }

        let result: Self = try saveCommand()
            .execute(options: options,
                     callbackQueue: .main,
                     childObjects: childObjects,
                     childFiles: childFiles)
        Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                self.saveCommand()
                    .executeAsync(options: options,
                                  callbackQueue: callbackQueue,
                                  childObjects: savedChildObjects,
                                  childFiles: savedChildFiles) { result in
                        callbackQueue.async {
                            if case .success(let foundResults) = result {
                                Self.updateKeychainIfNeeded([foundResults])
                            }

                            completion(result)
                        }
                    }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    func saveCommand() -> API.Command<Self, Self> {
        if isSaved {
            return updateCommand()
        }
        return createCommand()
    }

    // MARK: Saving ParseObjects - private
    private func createCommand() -> API.Command<Self, Self> {
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(SaveResponse.self, from: data).apply(to: self)
        }
        return API.Command<Self, Self>(method: .POST,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }

    private func updateCommand() -> API.Command<Self, Self> {
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: data).apply(to: self)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseInstallation {
    /**
     Deletes the `ParseInstallation` *synchronously* with the current data from the server
     and sets an error if one occurs.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    public func delete(options: API.Options = []) throws {
        _ = try deleteCommand().execute(options: options)
        Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
         do {
            try deleteCommand()
                .executeAsync(options: options) { result in
                    callbackQueue.async {
                        switch result {

                        case .success:
                            Self.updateKeychainIfNeeded([self], deleting: true)
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
         } catch let error as ParseError {
            callbackQueue.async {
                completion(.failure(error))
            }
         } catch {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError, message: error.localizedDescription)))
            }
         }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<NoBody, NoBody> {
        guard isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(
            method: .DELETE,
            path: endpoint
        ) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {

    /**
     Saves a collection of installations *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var error: ParseError?

        let installations = map { $0 }
        for installation in installations {
            let group = DispatchGroup()
            group.enter()
            installation.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                //If an error occurs, everything should be skipped
                if parseError != nil {
                    error = parseError
                }
                savedChildObjects.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childObjects[key] == nil {
                        childObjects[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                savedChildFiles.forEach {(key, value) in
                    if error != nil {
                        return
                    }
                    if childFiles[key] == nil {
                        childFiles[key] = value
                    } else {
                        error = ParseError(code: .unknownError, message: "circular dependency")
                        return
                    }
                }
                group.leave()
            }
            group.wait()
            if let error = error {
                throw error
            }
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let commands = map { $0.saveCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0)
                .execute(options: options,
                         callbackQueue: .main,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
        return returnBatch
    }

    /**
     Saves a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let queue = DispatchQueue(label: "com.parse.saveAll", qos: .default,
                                  attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        queue.sync {
            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            var childObjects = [String: PointerType]()
            var childFiles = [UUID: ParseFile]()
            var error: ParseError?

            let installations = map { $0 }
            for installation in installations {
                let group = DispatchGroup()
                group.enter()
                installation
                    .ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                    //If an error occurs, everything should be skipped
                    if parseError != nil {
                        error = parseError
                    }
                    savedChildObjects.forEach {(key, value) in
                        if error != nil {
                            return
                        }
                        if childObjects[key] == nil {
                            childObjects[key] = value
                        } else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                    }
                    savedChildFiles.forEach {(key, value) in
                        if error != nil {
                            return
                        }
                        if childFiles[key] == nil {
                            childFiles[key] = value
                        } else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                    }
                    group.leave()
                }
                group.wait()
                if let error = error {
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                    return
                }
            }

            var returnBatch = [(Result<Self.Element, ParseError>)]()
            let commands = map { $0.saveCommand() }
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, Self.Element>
                        .batch(commands: batch)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: childObjects,
                                      childFiles: childFiles) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            callbackQueue.async {
                                Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
                                completion(.success(returnBatch))
                            }
                        }
                        completed += 1
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            }
        }
    }

    /**
     Fetches a collection of installations *synchronously* all at once and throws an error if necessary.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: `ParseError`
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which installations are returned are not guarenteed. You shouldn't expect results in
     any particular order.
    */
    func fetchAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            let query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
                .limit(uniqueObjectIds.count)
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
            Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of installations all at once *asynchronously* and executes the completion block when done.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which installations are returned are not guarenteed. You shouldn't expect results in
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
                    callbackQueue.async {
                        Self.Element.updateKeychainIfNeeded(fetchedObjects)
                        completion(.success(fetchedObjectsToReturn))
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            callbackQueue.async {
                completion(.failure(ParseError(code: .unknownError,
                                               message: "all items to fetch must be of the same class")))
            }
        }
    }

    /**
     Deletes a collection of installations *synchronously* all at once and throws an error if necessary.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: `ParseError`
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, (Result<Void, ParseError>)>
                .batch(commands: $0)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }

        Self.Element.updateKeychainIfNeeded(compactMap {$0})
        return returnBatch
    }

    /**
     Deletes a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[ParseError?], ParseError>)`.
     Each element in the array is either `nil` if the delete successful or a `ParseError` if it failed.
     1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
     array of other Parse.Error objects. Each error object in this array
     has an "object" property that references the object that could not be
     deleted (for instance, because that object could not be found).
     2. A non-aggregate Parse.Error. This indicates a serious error that
     caused the delete operation to be aborted partway through (for
     instance, a connection failure in the middle of the delete).
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        do {
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch)
                        .executeAsync(options: options) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            callbackQueue.async {
                                Self.Element.updateKeychainIfNeeded(self.compactMap {$0})
                                completion(.success(returnBatch))
                            }
                        }
                        completed += 1
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
            }
        } catch {
            callbackQueue.async {
                guard let parseError = error as? ParseError else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                    return
                }
                completion(.failure(parseError))
            }
        }
    }
} // swiftlint:disable:this file_length
