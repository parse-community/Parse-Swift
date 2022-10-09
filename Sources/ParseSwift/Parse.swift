import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

// MARK: Internal

internal struct Parse {
    static var configuration: ParseConfiguration!
    static var sessionDelegate: ParseURLSessionDelegate!
}

internal func initialize(applicationId: String,
                         clientKey: String? = nil,
                         masterKey: String? = nil,
                         serverURL: URL,
                         liveQueryServerURL: URL? = nil,
                         requiringCustomObjectIds: Bool = false,
                         usingTransactions: Bool = false,
                         usingEqualQueryConstraint: Bool = false,
                         usingPostForQuery: Bool = false,
                         primitiveStore: ParsePrimitiveStorable? = nil,
                         requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                         cacheMemoryCapacity: Int = 512_000,
                         cacheDiskCapacity: Int = 10_000_000,
                         migratingFromObjcSDK: Bool = false,
                         usingDataProtectionKeychain: Bool = false,
                         deletingKeychainIfNeeded: Bool = false,
                         httpAdditionalHeaders: [AnyHashable: Any]? = nil,
                         maxConnectionAttempts: Int = 5,
                         testing: Bool = false,
                         authentication: ((URLAuthenticationChallenge,
                                          (URLSession.AuthChallengeDisposition,
                                           URLCredential?) -> Void) -> Void)? = nil) {
    var configuration = ParseConfiguration(applicationId: applicationId,
                                           clientKey: clientKey,
                                           masterKey: masterKey,
                                           serverURL: serverURL,
                                           liveQueryServerURL: liveQueryServerURL,
                                           requiringCustomObjectIds: requiringCustomObjectIds,
                                           usingTransactions: usingTransactions,
                                           usingEqualQueryConstraint: usingEqualQueryConstraint,
                                           usingPostForQuery: usingPostForQuery,
                                           primitiveStore: primitiveStore,
                                           requestCachePolicy: requestCachePolicy,
                                           cacheMemoryCapacity: cacheMemoryCapacity,
                                           cacheDiskCapacity: cacheDiskCapacity,
                                           usingDataProtectionKeychain: usingDataProtectionKeychain,
                                           deletingKeychainIfNeeded: deletingKeychainIfNeeded,
                                           httpAdditionalHeaders: httpAdditionalHeaders,
                                           maxConnectionAttempts: maxConnectionAttempts,
                                           authentication: authentication)
    configuration.isMigratingFromObjcSDK = migratingFromObjcSDK
    configuration.isTestingSDK = testing
    initialize(configuration: configuration)
}

internal func deleteKeychainIfNeeded() {
    #if !os(Linux) && !os(Android) && !os(Windows)
    // Clear items out of the Keychain on app first run.
    if UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) == nil {
        if Parse.configuration.isDeletingKeychainIfNeeded {
            try? KeychainStore.old.deleteAll()
            try? KeychainStore.shared.deleteAll()
        }
        Parse.configuration.keychainAccessGroup = .init()
        clearCache()
        // This is no longer the first run
        UserDefaults.standard.setValue(String(ParseConstants.bundlePrefix),
                                       forKey: ParseConstants.bundlePrefix)
        UserDefaults.standard.synchronize()
    }
    #endif
}

// MARK: Public - All Platforms

/// The current `ParseConfiguration` for the ParseSwift client.
public var configuration: ParseConfiguration {
    Parse.configuration
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter configuration: The Parse configuration.
 - important: It is recomended to only specify `masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
public func initialize(configuration: ParseConfiguration) {
    Parse.configuration = configuration
    Parse.sessionDelegate = ParseURLSessionDelegate(callbackQueue: .main,
                                                    authentication: configuration.authentication)
    URLSession.updateParseURLSession()
    deleteKeychainIfNeeded()

    #if !os(Linux) && !os(Android) && !os(Windows)
    if let keychainAccessGroup = ParseKeychainAccessGroup.current {
        Parse.configuration.keychainAccessGroup = keychainAccessGroup
    } else {
        ParseKeychainAccessGroup.current = ParseKeychainAccessGroup()
    }
    #endif

    do {
        let previousSDKVersion = try ParseVersion(ParseVersion.current)
        let currentSDKVersion = try ParseVersion(ParseConstants.version)
        let oneNineEightSDKVersion = try ParseVersion("1.9.8")

        // All migrations from previous versions to current should occur here:
        #if !os(Linux) && !os(Android) && !os(Windows)
        if previousSDKVersion < oneNineEightSDKVersion {
            // Old macOS Keychain cannot be used because it is global to all apps.
            _ = KeychainStore.old
            try? KeychainStore.shared.copy(KeychainStore.old,
                                           oldAccessGroup: configuration.keychainAccessGroup,
                                           newAccessGroup: configuration.keychainAccessGroup)
            // Need to delete the old Keychain because a new one is created with bundleId.
            try? KeychainStore.old.deleteAll()
        }
        #endif
        if currentSDKVersion > previousSDKVersion {
            ParseVersion.current = currentSDKVersion.string
        }
    } catch {
        // Migrate old installations made with ParseSwift < 1.3.0
        if let currentInstallation = BaseParseInstallation.current {
            if currentInstallation.objectId == nil {
                BaseParseInstallation.deleteCurrentContainerFromKeychain()
                // Prepare installation
                BaseParseInstallation.createNewInstallationIfNeeded()
            }
        } else {
            // Prepare installation
            BaseParseInstallation.createNewInstallationIfNeeded()
        }
        ParseVersion.current = ParseConstants.version
    }

    // Migrate installations with installationId, but missing
    // currentInstallation, ParseSwift < 1.9.10
    if let installationId = BaseParseInstallation.currentContainer.installationId,
       BaseParseInstallation.currentContainer.currentInstallation == nil {
        if let foundInstallation = try? BaseParseInstallation
            .query("installationId" == installationId)
            .first(options: [.cachePolicy(.reloadIgnoringLocalCacheData)]) {
            let newContainer = CurrentInstallationContainer<BaseParseInstallation>(currentInstallation: foundInstallation,
                                                                                   installationId: installationId)
            BaseParseInstallation.currentContainer = newContainer
            BaseParseInstallation.saveCurrentContainerToKeychain()
        }
    }
    BaseParseInstallation.createNewInstallationIfNeeded()

    #if !os(Linux) && !os(Android) && !os(Windows)
    if configuration.isMigratingFromObjcSDK {
        if let objcParseKeychain = KeychainStore.objectiveC {
            guard let installationId: String = objcParseKeychain.objectObjectiveC(forKey: "installationId"),
                  BaseParseInstallation.current?.installationId != installationId else {
                return
            }
            var updatedInstallation = BaseParseInstallation.current
            updatedInstallation?.installationId = installationId
            BaseParseInstallation.currentContainer.installationId = installationId
            BaseParseInstallation.currentContainer.currentInstallation = updatedInstallation
            BaseParseInstallation.saveCurrentContainerToKeychain()
        }
    }
    #endif
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter applicationId: The application id for your Parse application.
 - parameter clientKey: The client key for your Parse application.
 - parameter masterKey: The master key for your Parse application. This key should only be
 specified when using the SDK on a server.
 - parameter serverURL: The server URL to connect to Parse Server.
 - parameter liveQueryServerURL: The live query server URL to connect to Parse Server.
 - parameter requiringCustomObjectIds: Requires `objectId`'s to be created on the client
 side for each object. Must be enabled on the server to work.
 - parameter usingTransactions: Use transactions when saving/updating multiple objects.
 - parameter usingEqualQueryConstraint: Use the **$eq** query constraint when querying.
 - parameter usingPostForQuery: Use **POST** instead of **GET** when making query calls.
 Defaults to **false**.
 - parameter primitiveStore: A key/value store that conforms to the `ParseKeyValueStore`
 protocol. Defaults to `nil` in which one will be created an memory, but never persisted. For Linux, this
 this is the only store available since there is no Keychain. Linux, Android, and Windows users should
 replace this store with an encrypted one.
 - parameter requestCachePolicy: The default caching policy for all http requests that determines
 when to return a response from the cache. Defaults to `useProtocolCachePolicy`. See Apple's [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
 for more info.
 - parameter cacheMemoryCapacity: The memory capacity of the cache, in bytes. Defaults to 512KB.
 - parameter cacheDiskCapacity: The disk capacity of the cache, in bytes. Defaults to 10MB.
 - parameter usingDataProtectionKeychain: Sets `kSecUseDataProtectionKeychain` to **true**. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)
 for more info. Defaults to **false**.
 - parameter deletingKeychainIfNeeded: Deletes the Parse Keychain when the app is running for the first time.
 Defaults to **false**.
 - parameter httpAdditionalHeaders: A dictionary of additional headers to send with requests. See Apple's
 [documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders)
 for more info.
 - parameter maxConnectionAttempts: Maximum number of times to try to connect to Parse Server.
 Defaults to 5.
 - parameter parseFileTransfer: Override the default transfer behavior for `ParseFile`'s.
 Allows for direct uploads to other file storage providers.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 - important: It is recomended to only specify `masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    liveQueryServerURL: URL? = nil,
    requiringCustomObjectIds: Bool = false,
    usingTransactions: Bool = false,
    usingEqualQueryConstraint: Bool = false,
    usingPostForQuery: Bool = false,
    primitiveStore: ParsePrimitiveStorable? = nil,
    requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    cacheMemoryCapacity: Int = 512_000,
    cacheDiskCapacity: Int = 10_000_000,
    usingDataProtectionKeychain: Bool = false,
    deletingKeychainIfNeeded: Bool = false,
    httpAdditionalHeaders: [AnyHashable: Any]? = nil,
    maxConnectionAttempts: Int = 5,
    parseFileTransfer: ParseFileTransferable? = nil,
    authentication: ((URLAuthenticationChallenge,
                      (URLSession.AuthChallengeDisposition,
                       URLCredential?) -> Void) -> Void)? = nil
) {
    let configuration = ParseConfiguration(applicationId: applicationId,
                                           clientKey: clientKey,
                                           masterKey: masterKey,
                                           serverURL: serverURL,
                                           liveQueryServerURL: liveQueryServerURL,
                                           requiringCustomObjectIds: requiringCustomObjectIds,
                                           usingTransactions: usingTransactions,
                                           usingEqualQueryConstraint: usingEqualQueryConstraint,
                                           usingPostForQuery: usingPostForQuery,
                                           primitiveStore: primitiveStore,
                                           requestCachePolicy: requestCachePolicy,
                                           cacheMemoryCapacity: cacheMemoryCapacity,
                                           cacheDiskCapacity: cacheDiskCapacity,
                                           usingDataProtectionKeychain: usingDataProtectionKeychain,
                                           deletingKeychainIfNeeded: deletingKeychainIfNeeded,
                                           httpAdditionalHeaders: httpAdditionalHeaders,
                                           maxConnectionAttempts: maxConnectionAttempts,
                                           parseFileTransfer: parseFileTransfer,
                                           authentication: authentication)
    initialize(configuration: configuration)
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter applicationId: The application id for your Parse application.
 - parameter clientKey: The client key for your Parse application.
 - parameter masterKey: The master key for your Parse application. This key should only be
 specified when using the SDK on a server.
 - parameter serverURL: The server URL to connect to Parse Server.
 - parameter liveQueryServerURL: The live query server URL to connect to Parse Server.
 - parameter allowingCustomObjectIds: Requires `objectId`'s to be created on the client
 side for each object. Must be enabled on the server to work.
 - parameter usingTransactions: Use transactions when saving/updating multiple objects.
 - parameter usingEqualQueryConstraint: Use the **$eq** query constraint when querying.
 - parameter usingPostForQuery: Use **POST** instead of **GET** when making query calls.
 Defaults to **false**.
 - parameter keyValueStore: A key/value store that conforms to the `ParseKeyValueStore`
 protocol. Defaults to `nil` in which one will be created an memory, but never persisted. For Linux, this
 this is the only store available since there is no Keychain. Linux, Android, and Windows users should
 replace this store with an encrypted one.
 - parameter requestCachePolicy: The default caching policy for all http requests that determines
 when to return a response from the cache. Defaults to `useProtocolCachePolicy`. See Apple's [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
 for more info.
 - parameter cacheMemoryCapacity: The memory capacity of the cache, in bytes. Defaults to 512KB.
 - parameter cacheDiskCapacity: The disk capacity of the cache, in bytes. Defaults to 10MB.
 - parameter usingDataProtectionKeychain: Sets `kSecUseDataProtectionKeychain` to **true**. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)
 for more info. Defaults to **false**.
 - parameter deletingKeychainIfNeeded: Deletes the Parse Keychain when the app is running for the first time.
 Defaults to **false**.
 - parameter httpAdditionalHeaders: A dictionary of additional headers to send with requests. See Apple's
 [documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders)
 for more info.
 - parameter maxConnectionAttempts: Maximum number of times to try to connect to Parse Server.
 Defaults to 5.
 - parameter parseFileTransfer: Override the default transfer behavior for `ParseFile`'s.
 Allows for direct uploads to other file storage providers.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 - important: It is recomended to only specify `masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
@available(*, deprecated, message: "Change: allowingCustomObjectIds->requiringCustomObjectIds and keyValueStore->primitiveStore")
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    liveQueryServerURL: URL? = nil,
    allowingCustomObjectIds: Bool,
    usingTransactions: Bool = false,
    usingEqualQueryConstraint: Bool = false,
    usingPostForQuery: Bool = false,
    keyValueStore: ParsePrimitiveStorable? = nil,
    requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    cacheMemoryCapacity: Int = 512_000,
    cacheDiskCapacity: Int = 10_000_000,
    usingDataProtectionKeychain: Bool = false,
    deletingKeychainIfNeeded: Bool = false,
    httpAdditionalHeaders: [AnyHashable: Any]? = nil,
    maxConnectionAttempts: Int = 5,
    parseFileTransfer: ParseFileTransferable? = nil,
    authentication: ((URLAuthenticationChallenge,
                      (URLSession.AuthChallengeDisposition,
                       URLCredential?) -> Void) -> Void)? = nil
) {
    initialize(applicationId: applicationId,
               clientKey: clientKey,
               masterKey: masterKey,
               serverURL: serverURL,
               liveQueryServerURL: liveQueryServerURL,
               requiringCustomObjectIds: allowingCustomObjectIds,
               usingTransactions: usingTransactions,
               usingEqualQueryConstraint: usingEqualQueryConstraint,
               usingPostForQuery: usingPostForQuery,
               primitiveStore: keyValueStore,
               requestCachePolicy: requestCachePolicy,
               cacheMemoryCapacity: cacheMemoryCapacity,
               cacheDiskCapacity: cacheDiskCapacity,
               usingDataProtectionKeychain: usingDataProtectionKeychain,
               deletingKeychainIfNeeded: deletingKeychainIfNeeded,
               httpAdditionalHeaders: httpAdditionalHeaders,
               maxConnectionAttempts: maxConnectionAttempts,
               parseFileTransfer: parseFileTransfer,
               authentication: authentication)
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter applicationId: The application id for your Parse application.
 - parameter clientKey: The client key for your Parse application.
 - parameter masterKey: The master key for your Parse application. This key should only be
 specified when using the SDK on a server.
 - parameter serverURL: The server URL to connect to Parse Server.
 - parameter liveQueryServerURL: The live query server URL to connect to Parse Server.
 - parameter allowingCustomObjectIds: Requires `objectId`'s to be created on the client
 side for each object. Must be enabled on the server to work.
 - parameter usingTransactions: Use transactions when saving/updating multiple objects.
 - parameter usingEqualQueryConstraint: Use the **$eq** query constraint when querying.
 - parameter usingPostForQuery: Use **POST** instead of **GET** when making query calls.
 Defaults to **false**.
 - parameter keyValueStore: A key/value store that conforms to the `ParseKeyValueStore`
 protocol. Defaults to `nil` in which one will be created an memory, but never persisted. For Linux, this
 this is the only store available since there is no Keychain. Linux, Android, and Windows users should
 replace this store with an encrypted one.
 - parameter requestCachePolicy: The default caching policy for all http requests that determines
 when to return a response from the cache. Defaults to `useProtocolCachePolicy`. See Apple's [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
 for more info.
 - parameter cacheMemoryCapacity: The memory capacity of the cache, in bytes. Defaults to 512KB.
 - parameter cacheDiskCapacity: The disk capacity of the cache, in bytes. Defaults to 10MB.
 - parameter migratingFromObjcSDK: If your app previously used the iOS Objective-C SDK, setting this value
 to **true** will attempt to migrate relevant data stored in the Keychain to ParseSwift. Defaults to **false**.
 - parameter usingDataProtectionKeychain: Sets `kSecUseDataProtectionKeychain` to **true**. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)
 for more info. Defaults to **false**.
 - parameter deletingKeychainIfNeeded: Deletes the Parse Keychain when the app is running for the first time.
 Defaults to **false**.
 - parameter httpAdditionalHeaders: A dictionary of additional headers to send with requests. See Apple's
 [documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders)
 for more info.
 - parameter maxConnectionAttempts: Maximum number of times to try to connect to Parse Server.
 Defaults to 5.
 - parameter parseFileTransfer: Override the default transfer behavior for `ParseFile`'s.
 Allows for direct uploads to other file storage providers.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 - important: It is recomended to only specify `masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
@available(*, deprecated, message: "Remove the migratingFromObjcSDK argument")
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    masterKey: String? = nil,
    serverURL: URL,
    liveQueryServerURL: URL? = nil,
    allowingCustomObjectIds: Bool = false,
    usingTransactions: Bool = false,
    usingEqualQueryConstraint: Bool = false,
    usingPostForQuery: Bool = false,
    keyValueStore: ParseKeyValueStore? = nil,
    requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    cacheMemoryCapacity: Int = 512_000,
    cacheDiskCapacity: Int = 10_000_000,
    migratingFromObjcSDK: Bool,
    usingDataProtectionKeychain: Bool = false,
    deletingKeychainIfNeeded: Bool = false,
    httpAdditionalHeaders: [AnyHashable: Any]? = nil,
    maxConnectionAttempts: Int = 5,
    parseFileTransfer: ParseFileTransferable? = nil,
    authentication: ((URLAuthenticationChallenge,
                      (URLSession.AuthChallengeDisposition,
                       URLCredential?) -> Void) -> Void)? = nil
) {
    var configuration = ParseConfiguration(applicationId: applicationId,
                                           clientKey: clientKey,
                                           masterKey: masterKey,
                                           serverURL: serverURL,
                                           liveQueryServerURL: liveQueryServerURL,
                                           requiringCustomObjectIds: allowingCustomObjectIds,
                                           usingTransactions: usingTransactions,
                                           usingEqualQueryConstraint: usingEqualQueryConstraint,
                                           usingPostForQuery: usingPostForQuery,
                                           primitiveStore: keyValueStore,
                                           requestCachePolicy: requestCachePolicy,
                                           cacheMemoryCapacity: cacheMemoryCapacity,
                                           cacheDiskCapacity: cacheDiskCapacity,
                                           usingDataProtectionKeychain: usingDataProtectionKeychain,
                                           deletingKeychainIfNeeded: deletingKeychainIfNeeded,
                                           httpAdditionalHeaders: httpAdditionalHeaders,
                                           maxConnectionAttempts: maxConnectionAttempts,
                                           parseFileTransfer: parseFileTransfer,
                                           authentication: authentication)
    configuration.isMigratingFromObjcSDK = migratingFromObjcSDK
    initialize(configuration: configuration)
}

/**
 Update the authentication callback.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 */
public func updateAuthentication(_ authentication: ((URLAuthenticationChallenge,
                                                     (URLSession.AuthChallengeDisposition,
                                                      URLCredential?) -> Void) -> Void)?) {
    Parse.sessionDelegate = ParseURLSessionDelegate(callbackQueue: .main,
                                                    authentication: authentication)
    URLSession.updateParseURLSession()
}

/**
 Manually remove all stored cache.
 - note: The OS typically handles this automatically.
 */
public func clearCache() {
    URLSession.parse.configuration.urlCache?.removeAllCachedResponses()
}

// MARK: Public - Apple Platforms

#if !os(Linux) && !os(Android) && !os(Windows)

/**
 Delete the Parse iOS Objective-C SDK Keychain from the device.
 - note: ParseSwift uses a different Keychain. After migration, the iOS Objective-C SDK Keychain is no longer needed.
 - warning: The keychain cannot be recovered after deletion.
 */
public func deleteObjectiveCKeychain() throws {
    try KeychainStore.objectiveC?.deleteAllObjectiveC()
}

/**
 Sets all of the items in the Parse Keychain to a specific access group.
 Apps in the same access group can share Keychain items. See Apple's
  [documentation](https://developer.apple.com/documentation/security/ksecattraccessgroup)
  for more information.
 - parameter accessGroup: The name of the access group.
 - parameter synchronizeAcrossDevices: **true** to synchronize all necessary Parse Keychain items to
 other devices using iCloud. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecattrsynchronizable)
 for more information. **false** to disable synchronization.
 - throws: An error of type `ParseError`.
 - returns: **true** if the Keychain was moved to the new `accessGroup`, **false** otherwise.
 - important: Setting `synchronizeAcrossDevices == true` requires `accessGroup` to be
 set to a valid [keychain group](https://developer.apple.com/documentation/security/ksecattraccessgroup).
 */
@discardableResult public func setAccessGroup(_ accessGroup: String?,
                                              synchronizeAcrossDevices: Bool) throws -> Bool {
    if synchronizeAcrossDevices && accessGroup == nil {
        throw ParseError(code: .unknownError,
                         message: "\"accessGroup\" must be set to a valid string when \"synchronizeAcrossDevices == true\"")
    }
    guard let currentAccessGroup = ParseKeychainAccessGroup.current else {
        throw ParseError(code: .unknownError,
                         message: "Problem unwrapping the current access group. Did you initialize the SDK before calling this method?")
    }
    let newKeychainAccessGroup = ParseKeychainAccessGroup(accessGroup: accessGroup,
                                                          isSyncingKeychainAcrossDevices: synchronizeAcrossDevices)
    guard newKeychainAccessGroup != currentAccessGroup else {
        ParseKeychainAccessGroup.current = newKeychainAccessGroup
        return true
    }
    do {
        try KeychainStore.shared.copy(KeychainStore.shared,
                                      oldAccessGroup: currentAccessGroup,
                                      newAccessGroup: newKeychainAccessGroup)
        ParseKeychainAccessGroup.current = newKeychainAccessGroup
    } catch {
        ParseKeychainAccessGroup.current = currentAccessGroup
        throw error
    }
    return true
}
#endif
