//
//  ParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/6/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseInstallation` protocol have a local representation of an
 installation persisted to the Keychain and Parse Server. This protocol inherits from the
 `ParseObject` protocol, and retains the same functionality of a `ParseObject`, but also extends
 it with installation-specific fields and related immutability and validity
 checks.

 A valid `ParseInstallation` can only be instantiated via
 *current* because the required identifier fields
 are readonly. The `timeZone` is also a readonly property which
 is automatically updated to match the device's time zone
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.
 `ParseInstallation`s which have a valid `deviceToken` and are saved to
 the Parse Server can be used to target push notifications. Use `setDeviceToken` to set the
 `deviceToken` properly.

 - warning: If the use of badge is desired, it should be retrieved by using UIKit, AppKit, etc. and
 stored in `ParseInstallation.badge` when saving/updating the installation.
 - warning: Linux, Android, and Windows developers should set `appName`,
 `appIdentifier`, and `appVersion` manually as `ParseSwift` does not have access
 to Bundle.main.
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

    /**
     The application name  for the `ParseInstallation`.
     */
    var appName: String? { get set }

    /**
     The application identifier for the `ParseInstallation`.
     */
    var appIdentifier: String? { get set }

    /**
     The application version for the `ParseInstallation`.
     */
    var appVersion: String? { get set }

    /**
     The sdk version for the `ParseInstallation`.
     */
    var parseVersion: String? { get set }

    /**
     The locale identifier for the `ParseInstallation`.
     */
    var localeIdentifier: String? { get set }
}

// MARK: Default Implementations
public extension ParseInstallation {
    static var className: String {
        "_Installation"
    }

    func mergeParse(with object: Self) throws -> Self {
        guard hasSameObjectId(as: object) else {
            throw ParseError(code: .unknownError,
                             message: "objectId's of objects do not match")
        }
        var updatedInstallation = self
        if shouldRestoreKey(\.ACL,
                             original: object) {
            updatedInstallation.ACL = object.ACL
        }
        if shouldRestoreKey(\.deviceType,
                             original: object) {
            updatedInstallation.deviceType = object.deviceType
        }
        if shouldRestoreKey(\.installationId,
                             original: object) {
            updatedInstallation.installationId = object.installationId
        }
        if shouldRestoreKey(\.deviceToken,
                                 original: object) {
            updatedInstallation.deviceToken = object.deviceToken
        }
        if shouldRestoreKey(\.badge,
                             original: object) {
            updatedInstallation.badge = object.badge
        }
        if shouldRestoreKey(\.timeZone,
                             original: object) {
            updatedInstallation.timeZone = object.timeZone
        }
        if shouldRestoreKey(\.channels,
                             original: object) {
            updatedInstallation.channels = object.channels
        }
        if shouldRestoreKey(\.appName,
                             original: object) {
            updatedInstallation.appName = object.appName
        }
        if shouldRestoreKey(\.appIdentifier,
                             original: object) {
            updatedInstallation.appIdentifier = object.appIdentifier
        }
        if shouldRestoreKey(\.appVersion,
                             original: object) {
            updatedInstallation.appVersion = object.appVersion
        }
        if shouldRestoreKey(\.parseVersion,
                             original: object) {
            updatedInstallation.parseVersion = object.parseVersion
        }
        if shouldRestoreKey(\.localeIdentifier,
                             original: object) {
            updatedInstallation.localeIdentifier = object.localeIdentifier
        }
        return updatedInstallation
    }

    func merge(with object: Self) throws -> Self {
        do {
            return try mergeAutomatically(object)
        } catch {
            return try mergeParse(with: object)
        }
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

    func endpoint(_ method: API.Method) -> API.Endpoint {
        if !Parse.configuration.isRequiringCustomObjectIds || method != .POST {
            return endpoint
        } else {
            return .installations
        }
    }

    func hasSameInstallationId<T: ParseInstallation>(as other: T) -> Bool {
        return other.className == className && other.installationId == installationId && installationId != nil
    }

    /**
     Sets the device token string property from an `Data`-encoded token.
     - parameter data: A token that identifies the device.
     */
    mutating public func setDeviceToken(_ data: Data) {
        let deviceTokenString = data.hexEncodedString()
        if deviceToken != deviceTokenString {
            deviceToken = deviceTokenString
        }
    }
}

// MARK: CurrentInstallationContainer
struct CurrentInstallationContainer<T: ParseInstallation>: Codable, Hashable {
    var currentInstallation: T?
    var installationId: String?
}

// MARK: Current Installation Support
public extension ParseInstallation {
    internal static var currentContainer: CurrentInstallationContainer<Self> {
        get {
            guard let installationInMemory: CurrentInstallationContainer<Self> =
                    try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                #if !os(Linux) && !os(Android) && !os(Windows)
                guard let installationFromKeyChain: CurrentInstallationContainer<Self> =
                        try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                else {
                    let newInstallationId = UUID().uuidString.lowercased()
                    var newInstallation = BaseParseInstallation()
                    newInstallation.installationId = newInstallationId
                    newInstallation.createInstallationId(newId: newInstallationId)
                    newInstallation.updateAutomaticInfo()
                    let newBaseInstallationContainer =
                        CurrentInstallationContainer<BaseParseInstallation>(currentInstallation: newInstallation,
                                                                            installationId: newInstallationId)
                    try? KeychainStore.shared.set(newBaseInstallationContainer,
                                                  for: ParseStorage.Keys.currentInstallation)
                    guard let installationFromKeyChain: CurrentInstallationContainer<Self> =
                            try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                    else {
                        // Could not create container correctly, return empty one.
                        return CurrentInstallationContainer<Self>()
                    }
                    try? ParseStorage.shared.set(installationFromKeyChain, for: ParseStorage.Keys.currentInstallation)
                    return installationFromKeyChain
                }
                return installationFromKeyChain
                #else
                let newInstallationId = UUID().uuidString.lowercased()
                var newInstallation = BaseParseInstallation()
                newInstallation.installationId = newInstallationId
                newInstallation.createInstallationId(newId: newInstallationId)
                newInstallation.updateAutomaticInfo()
                let newBaseInstallationContainer =
                    CurrentInstallationContainer<BaseParseInstallation>(currentInstallation: newInstallation,
                                                                        installationId: newInstallationId)
                try? ParseStorage.shared.set(newBaseInstallationContainer,
                                              for: ParseStorage.Keys.currentInstallation)
                guard let installationFromMemory: CurrentInstallationContainer<Self> =
                        try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                else {
                    // Could not create container correctly, return empty one.
                    return CurrentInstallationContainer<Self>()
                }
                return installationFromMemory
                #endif
            }
            return installationInMemory
        }
        set {
            try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentInstallation)
        }
    }

    internal static func updateInternalFieldsCorrectly() {

        if let currentContainerInstallationId = Self.currentContainer.installationId,
            Self.currentContainer.currentInstallation?.installationId !=
            currentContainerInstallationId {

            // If the user made changes, set back to the original
            Self.currentContainer.currentInstallation?.installationId =
            currentContainerInstallationId
        }

        // Always pull automatic info to ensure user made no changes to immutable values
        Self.currentContainer.currentInstallation?.updateAutomaticInfo()
    }

    internal static func saveCurrentContainerToKeychain() {
        Self.currentContainer.currentInstallation?.originalData = nil
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.set(currentContainer, for: ParseStorage.Keys.currentInstallation)
        #endif
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #endif
        // Prepare new installation
        BaseParseInstallation.createNewInstallationIfNeeded()
    }

    /**
     Gets/Sets properties of the current installation in the Keychain.

     - returns: Returns a `ParseInstallation` that is the current device. If there is none, returns `nil`.
    */
    internal(set) static var current: Self? {
        get {
            return Self.currentContainer.currentInstallation
        }
        set {
            Self.currentContainer.currentInstallation = newValue
            Self.updateInternalFieldsCorrectly()
        }
    }

    /**
     Copy the `ParseInstallation` *asynchronously* based on the `objectId`.
     On success, this saves the `ParseInstallation` to the keychain, so you can retrieve
     the current installation using *current*.

     - parameter objectId: The **id** of the `ParseInstallation` to become.
     - parameter copyEntireInstallation: When **true**, copies the entire `ParseInstallation`.
     When **false**, only the `channels` and `deviceToken` are copied; resulting in a new
     `ParseInstallation` for original `sessionToken`. Defaults to **true**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func become(_ objectId: String,
                       copyEntireInstallation: Bool = true,
                       options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard var currentInstallation = Self.current else {
            let error = ParseError(code: .unknownError,
                                   message: "Current installation does not exist")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        guard currentInstallation.objectId != objectId else {
            // If the installationId's are the same, assume successful replacement already occured.
            callbackQueue.async {
                completion(.success(currentInstallation))
            }
            return
        }
        currentInstallation.objectId = objectId
        currentInstallation.fetch(options: options, callbackQueue: callbackQueue) { result in
            switch result {
            case .success(var updatedInstallation):
                if copyEntireInstallation {
                    updatedInstallation.updateAutomaticInfo()
                    Self.currentContainer.installationId = updatedInstallation.installationId
                    Self.currentContainer.currentInstallation = updatedInstallation
                } else {
                    Self.current?.channels = updatedInstallation.channels
                    if Self.current?.deviceToken == nil {
                        Self.current?.deviceToken = updatedInstallation.deviceToken
                    }
                }
                Self.saveCurrentContainerToKeychain()
                guard let latestInstallation = Self.current else {
                    let error = ParseError(code: .unknownError,
                                           message: "Had trouble migrating the installation")
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                    return
                }
                latestInstallation.save(options: options,
                                        callbackQueue: callbackQueue,
                                        completion: completion)
            case .failure(let error):
                callbackQueue.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: Automatic Info
extension ParseInstallation {
    mutating func updateAutomaticInfo() {
        updateDeviceTypeFromDevice()
        updateTimeZoneFromDevice()
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

    mutating func updateVersionInfoFromDevice() {
        guard let appInfo = Bundle.main.infoDictionary else {
            return
        }
        #if !os(Linux) && !os(Android) && !os(Windows)
        #if TARGET_OS_MACCATALYST
        // If using an Xcode new enough to know about Mac Catalyst:
        // Mac Catalyst Apps use a prefix to the bundle ID. This should not be transmitted
        // to Parse Server. Catalyst apps should look like iOS apps otherwise
        // push and other services do not work properly.
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

        if parseVersion != ParseConstants.version {
            parseVersion = ParseConstants.version
        }
    }

    /**
     Save localeIdentifier in the following format: [language code]-[COUNTRY CODE].

     The language codes are two-letter lowercase ISO language codes (such as "en") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_639-1">ISO 639-1</a>.
     The country codes are two-letter uppercase ISO country codes (such as "US") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3">ISO 3166-1</a>.

     Many iOS locale identifiers do not contain the country code -> inconsistencies with Android/Windows Phone.
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
        guard let currentInstallation = Self.current else {
            return
        }

        var foundCurrentInstallationObjects = results.filter { $0.hasSameInstallationId(as: currentInstallation) }
        foundCurrentInstallationObjects = try foundCurrentInstallationObjects.sorted(by: {
            guard let firstUpdatedAt = $0.updatedAt,
                  let secondUpdatedAt = $1.updatedAt else {
                throw ParseError(code: .unknownError,
                                 message: "Objects from the server should always have an \"updatedAt\"")
            }
            return firstUpdatedAt.compare(secondUpdatedAt) == .orderedDescending
        })
        if let foundCurrentInstallation = foundCurrentInstallationObjects.first {
            if !deleting {
                Self.current = foundCurrentInstallation
                Self.saveCurrentContainerToKeychain()
            } else {
                Self.deleteCurrentContainerFromKeychain()
            }
        }
    }

    /**
     Fetches the `ParseInstallation` *synchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(includeKeys: [String]? = nil,
                      options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let result: Self = try fetchCommand(include: includeKeys)
            .execute(options: options)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Fetches the `ParseInstallation` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try fetchCommand(include: includeKeys)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    if case .success(let foundResult) = result {
                        do {
                            try Self.updateKeychainIfNeeded([foundResult])
                            completion(.success(foundResult))
                        } catch {
                            let defaultError = ParseError(code: .unknownError,
                                                          message: error.localizedDescription)
                            let parseError = error as? ParseError ?? defaultError
                            callbackQueue.async {
                                completion(.failure(parseError))
                            }
                        }
                    } else {
                        completion(result)
                    }
                }
         } catch {
            callbackQueue.async {
                if let error = error as? ParseError {
                    completion(.failure(error))
                } else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: error.localizedDescription)))
                }
            }
         }
    }

    func fetchCommand(include: [String]?) throws -> API.Command<Self, Self> {
        guard objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(Set(includeParams))"]
        }

        return API.Command(method: .GET,
                           path: endpoint,
                           params: params) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseInstallation {

    /**
     Saves the `ParseInstallation` *synchronously* and throws an error if there is an issue.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseInstallation`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
    */
    @discardableResult
    public func save(options: API.Options = []) throws -> Self {
        try save(ignoringCustomObjectIdConfig: false,
                 options: options)
    }

    /**
     Saves the `ParseInstallation` *synchronously* and throws an error if there is an issue.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
     - returns: Returns saved `ParseInstallation`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult
    public func save(ignoringCustomObjectIdConfig: Bool,
                     options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
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

        let result: Self = try saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
            .execute(options: options,
                     childObjects: childObjects,
                     childFiles: childFiles)
        try Self.updateKeychainIfNeeded([result])
        return result
    }

    /**
     Saves the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Creates the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func create(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Replaces the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func replace(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    /**
     Updates the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func update(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                completion(.success(object))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        command(method: method,
                options: options,
                callbackQueue: callbackQueue,
                completion: completion)
        #endif
    }

    func command(
        method: Method,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<Self, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        self.ensureDeepSave(options: options) { (savedChildObjects, savedChildFiles, error) in
            guard let parseError = error else {
                do {
                    let command: API.Command<Self, Self>!
                    switch method {
                    case .save:
                        command = try self.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                    case .create:
                        command = self.createCommand()
                    case .replace:
                        command = try self.replaceCommand()
                    case .update:
                        command = try self.updateCommand()
                    }
                    command
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue,
                                      childObjects: savedChildObjects,
                                      childFiles: savedChildFiles) { result in
                            if case .success(let foundResult) = result {
                                try? Self.updateKeychainIfNeeded([foundResult])
                            }
                            completion(result)
                        }
                } catch {
                    let defaultError = ParseError(code: .unknownError,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
                return
            }
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }

    func saveCommand(ignoringCustomObjectIdConfig: Bool = false) throws -> API.Command<Self, Self> {
        if Parse.configuration.isRequiringCustomObjectIds && objectId == nil && !ignoringCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
        if isSaved {
            return try replaceCommand() // MARK: Should be switched to "updateCommand" when server supports PATCH.
        }
        return createCommand()
    }

    // MARK: Saving ParseObjects - private
    func createCommand() -> API.Command<Self, Self> {
        var object = self
        if object.ACL == nil,
            let acl = try? ParseACL.defaultACL() {
            object.ACL = acl
        }
        let mapper = { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(CreateResponse.self, from: data).apply(to: object)
        }
        return API.Command<Self, Self>(method: .POST,
                                       path: endpoint(.POST),
                                       body: object,
                                       mapper: mapper)
    }

    func replaceCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(ReplaceResponse.self,
                                                                 from: data).apply(to: updatedObject)
            // MARK: The lines below should be removed when server supports PATCH.
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }

    func updateCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(UpdateResponse.self,
                                                                 from: data).apply(to: updatedObject)
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PATCH,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseInstallation {
    /**
     Deletes the `ParseInstallation` *synchronously* with the current data from the server.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(options: API.Options = []) throws {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        _ = try deleteCommand().execute(options: options)
        try Self.updateKeychainIfNeeded([self], deleting: true)
    }

    /**
     Deletes the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<Void, ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
         do {
            try deleteCommand()
                 .executeAsync(options: options,
                               callbackQueue: callbackQueue) { result in
                     switch result {

                     case .success:
                         do {
                             try Self.updateKeychainIfNeeded([self], deleting: true)
                             completion(.success(()))
                         } catch {
                             let defaultError = ParseError(code: .unknownError,
                                                           message: error.localizedDescription)
                             let parseError = error as? ParseError ?? defaultError
                             callbackQueue.async {
                                 completion(.failure(parseError))
                             }
                         }
                     case .failure(let error):
                         completion(.failure(error))
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
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.

     - returns: Returns a Result enum with the object if a save was successful or a `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult
    func saveAll(batchLimit limit: Int? = nil, // swiftlint:disable:this function_body_length
                 transaction: Bool = configuration.isUsingTransactions,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var childObjects = [String: PointerType]()
        var childFiles = [UUID: ParseFile]()
        var commands = [API.Command<Self.Element, Self.Element>]()
        var error: ParseError?

        try forEach {
            let installation = $0
            let group = DispatchGroup()
            group.enter()
            installation.ensureDeepSave(options: options,
                                        // swiftlint:disable:next line_length
                                        isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                // If an error occurs, everything should be skipped
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
            commands.append(try installation.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig))
        }

        var returnBatch = [(Result<Self.Element, ParseError>)]()
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, Self.Element>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options,
                         batching: true,
                         childObjects: childObjects,
                         childFiles: childFiles)
            returnBatch.append(contentsOf: currentBatch)
        }
        try Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
        return returnBatch
    }

    /**
     Saves a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func saveAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.save
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Creates a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func createAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.create
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Replaces a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func replaceAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.replace
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    /**
     Updates a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAll( // swiftlint:disable:this function_body_length cyclomatic_complexity
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        let method = Method.update
        #if compiler(>=5.5.2) && canImport(_Concurrency)
        Task {
            do {
                let objects = try await batchCommand(method: method,
                                                     batchLimit: limit,
                                                     transaction: transaction,
                                                     options: options,
                                                     callbackQueue: callbackQueue)
                completion(.success(objects))
            } catch {
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
        #else
        batchCommand(method: method,
                     batchLimit: limit,
                     transaction: transaction,
                     options: options,
                     callbackQueue: callbackQueue,
                     completion: completion)
        #endif
    }

    internal func batchCommand( // swiftlint:disable:this function_parameter_count
        method: Method,
        batchLimit limit: Int?,
        transaction: Bool,
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.batch.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.sync {
            var childObjects = [String: PointerType]()
            var childFiles = [UUID: ParseFile]()
            var error: ParseError?
            var commands = [API.Command<Self.Element, Self.Element>]()
            let installations = map { $0 }

            for installation in installations {
                let group = DispatchGroup()
                group.enter()
                installation
                    .ensureDeepSave(options: options,
                                    // swiftlint:disable:next line_length
                                    isShouldReturnIfChildObjectsFound: transaction) { (savedChildObjects, savedChildFiles, parseError) -> Void in
                    // If an error occurs, everything should be skipped
                    if let parseError = parseError {
                        error = parseError
                    }
                    savedChildObjects.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childObjects[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childObjects[key] = value
                    }
                    savedChildFiles.forEach {(key, value) in
                        guard error == nil else {
                            return
                        }
                        guard childFiles[key] == nil else {
                            error = ParseError(code: .unknownError, message: "circular dependency")
                            return
                        }
                        childFiles[key] = value
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

                do {
                    switch method {
                    case .save:
                        commands.append(
                            try installation.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                        )
                    case .create:
                        commands.append(installation.createCommand())
                    case .replace:
                        commands.append(try installation.replaceCommand())
                    case .update:
                        commands.append(try installation.updateCommand())
                    }
                } catch {
                    let defaultError = ParseError(code: .unknownError,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                    return
                }
            }

            do {
                var returnBatch = [(Result<Self.Element, ParseError>)]()

                let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
                try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
                let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
                var completed = 0
                for batch in batches {
                    API.Command<Self.Element, Self.Element>
                            .batch(commands: batch, transaction: transaction)
                            .executeAsync(options: options,
                                          batching: true,
                                          callbackQueue: callbackQueue,
                                          childObjects: childObjects,
                                          childFiles: childFiles) { results in
                        switch results {

                        case .success(let saved):
                            returnBatch.append(contentsOf: saved)
                            if completed == (batches.count - 1) {
                                try? Self.Element.updateKeychainIfNeeded(returnBatch.compactMap {try? $0.get()})
                                completion(.success(returnBatch))
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
                let defaultError = ParseError(code: .unknownError,
                                              message: error.localizedDescription)
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Fetches a collection of installations *synchronously* all at once and throws an error if necessary.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns a Result enum with the object if a fetch was successful or a `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which installations are returned are not guarenteed. You should not expect results in
     any particular order.
    */
    func fetchAll(includeKeys: [String]? = nil,
                  options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {

        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
                .limit(uniqueObjectIds.count)

            if let include = includeKeys {
                query = query.include(include)
            }

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
            try Self.Element.updateKeychainIfNeeded(fetchedObjects)
            return fetchedObjectsToReturn
        } else {
            throw ParseError(code: .unknownError, message: "all items to fetch must be of the same class")
        }
    }

    /**
     Fetches a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - warning: The order in which installations are returned are not guarenteed. You should not expect results in
     any particular order.
    */
    func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
    ) {
        if (allSatisfy { $0.className == Self.Element.className}) {
            let uniqueObjectIds = Set(compactMap { $0.objectId })
            var query = Self.Element.query(containedIn(key: "objectId", array: [uniqueObjectIds]))
            if let include = includeKeys {
                query = query.include(include)
            }
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
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.

     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
        1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
        array of other Parse.Error objects. Each error object in this array
        has an "object" property that references the object that could not be
        deleted (for instance, because that object could not be found).
        2. A non-aggregate Parse.Error. This indicates a serious error that
        caused the delete operation to be aborted partway through (for
        instance, a connection failure in the middle of the delete).
     - throws: An error of type `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(batchLimit limit: Int? = nil,
                   transaction: Bool = configuration.isUsingTransactions,
                   options: API.Options = []) throws -> [(Result<Void, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var returnBatch = [(Result<Void, ParseError>)]()
        let commands = try map { try $0.deleteCommand() }
        let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
        try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
        let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
        try batches.forEach {
            let currentBatch = try API.Command<Self.Element, (Result<Void, ParseError>)>
                .batch(commands: $0, transaction: transaction)
                .execute(options: options)
            returnBatch.append(contentsOf: currentBatch)
        }

        try Self.Element.updateKeychainIfNeeded(compactMap {$0},
                                                deleting: true)
        return returnBatch
    }

    /**
     Deletes a collection of installations all at once *asynchronously* and executes the completion block when done.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
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
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func deleteAll(
        batchLimit limit: Int? = nil,
        transaction: Bool = configuration.isUsingTransactions,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
    ) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        do {
            var returnBatch = [(Result<Void, ParseError>)]()
            let commands = try map({ try $0.deleteCommand() })
            let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
            try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
            let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)
            var completed = 0
            for batch in batches {
                API.Command<Self.Element, ParseError?>
                        .batch(commands: batch, transaction: transaction)
                        .executeAsync(options: options,
                                      callbackQueue: callbackQueue) { results in
                    switch results {

                    case .success(let saved):
                        returnBatch.append(contentsOf: saved)
                        if completed == (batches.count - 1) {
                            try? Self.Element.updateKeychainIfNeeded(self.compactMap {$0},
                                                                     deleting: true)
                            completion(.success(returnBatch))
                        }
                        completed += 1
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                }
            }
        } catch {
            let defaultError = ParseError(code: .unknownError,
                                          message: error.localizedDescription)
            let parseError = error as? ParseError ?? defaultError
            callbackQueue.async {
                completion(.failure(parseError))
            }
        }
    }
}

#if !os(Linux) && !os(Android) && !os(Windows)
// MARK: Migrate from Objective-C SDK
public extension ParseInstallation {

    /**
     Migrates the `ParseInstallation` *asynchronously* from the Objective-C SDK Keychain.

     - parameter copyEntireInstallation: When **true**, copies the
     entire `ParseInstallation` from the Objective-C SDK Keychain to the Swift SDK. When
     **false**, only the `channels` and `deviceToken` are copied from the Objective-C
     SDK Keychain; resulting in a new `ParseInstallation` for original `sessionToken`.
     Defaults to **true**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: When initializing the Swift SDK, `migratingFromObjcSDK` should be set to **false**
     when calling this method.
     - warning: The latest **PFInstallation** from the Objective-C SDK should be saved to your
     Parse Server before calling this method. This method assumes **PFInstallation.installationId**
     is saved to the Keychain. If the **installationId** is not saved to the Keychain, this method will
     not work.
    */
    @available(*, deprecated, message: "This does not work, use become() instead")
    static func migrateFromObjCKeychain(copyEntireInstallation: Bool = true,
                                        options: API.Options = [],
                                        callbackQueue: DispatchQueue = .main,
                                        completion: @escaping (Result<Self, ParseError>) -> Void) {
        guard let objcParseKeychain = KeychainStore.objectiveC,
              let oldInstallationId: String = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            let error = ParseError(code: .unknownError,
                                   message: "Could not find Installation in the Objective-C SDK Keychain")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        become(oldInstallationId,
               copyEntireInstallation: copyEntireInstallation,
               completion: completion)
    }

    /**
     Deletes the Objective-C Keychain along with the Objective-C `ParseInstallation`
     from the Parse Server *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: It is recommended to only use this method after a succesfful migration. Calling this
     method will destroy the entire Objective-C Keychain and `ParseInstallation` on the Parse
     Server.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func deleteObjCKeychain(options: API.Options = [],
                                   callbackQueue: DispatchQueue = .main,
                                   completion: @escaping (Result<Void, ParseError>) -> Void) {
        guard let objcParseKeychain = KeychainStore.objectiveC,
              let oldInstallationId: String = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            let error = ParseError(code: .unknownError,
                                   message: "Could not find Installation in the Objective-C SDK Keychain")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        guard var currentInstallation = Self.current else {
            let error = ParseError(code: .unknownError,
                                   message: "Current installation does not exist")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        currentInstallation.installationId = oldInstallationId
        do {
            try deleteObjectiveCKeychain()
            // Only delete the `ParseInstallation` on Parse Server if it is not current.
            guard Self.current?.installationId == oldInstallationId else {
                currentInstallation.delete(options: options,
                                           callbackQueue: callbackQueue,
                                           completion: completion)
                return
            }
            callbackQueue.async {
                completion(.success(()))
            }
        } catch {
            let parseError = ParseError(code: .unknownError,
                                        message: error.localizedDescription)
            callbackQueue.async {
                completion(.failure(parseError))
            }
            return
        }
    }
}
#endif // swiftlint:disable:this file_length
