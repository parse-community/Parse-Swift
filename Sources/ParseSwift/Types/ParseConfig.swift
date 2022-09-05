//
//  ParseConfig.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/22/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseConfig` protocol are able to access the Config on the Parse Server.
 When conforming to `ParseConfig`, any properties added can be retrieved by the client or updated on
 the server. The current `ParseConfig` is persisted to the Keychain and Parse Server.
*/
public protocol ParseConfig: ParseTypeable {}

// MARK: Update
extension ParseConfig {

    /**
     Fetch the Config *synchronously*.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - returns: Returns `Self`.
        - throws: An error of type `ParseError`.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = []) throws -> Self {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try fetchCommand().execute(options: options)
    }

    /**
     Fetch the Config *asynchronously*.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when retrieving the config completes or fails.
        It should have the following argument signature: `(Result<Self, ParseError>)`.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        fetchCommand()
            .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                completion(result)
            }
    }

    internal func fetchCommand() -> API.NonParseBodyCommand<Self, Self> {

        return API.NonParseBodyCommand(method: .GET,
                                       path: .config) { (data) -> Self in
            let fetched = try ParseCoding.jsonDecoder().decode(ConfigFetchResponse<Self>.self, from: data).params
            Self.updateKeychainIfNeeded(fetched)
            return fetched
        }
    }
}

// MARK: Update
extension ParseConfig {

    /**
     Update the Config *synchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns **true** if updated, **false** otherwise.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(options: API.Options = []) throws -> Bool {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try updateCommand().execute(options: options)
    }

    /**
     Update the Config *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when retrieving the config completes or fails.
     It should have the following argument signature: `(Result<Bool, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Bool, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        updateCommand()
            .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                completion(result)
            }
    }

    internal func updateCommand() -> API.NonParseBodyCommand<ConfigUpdateBody<Self>, Bool> {
        let body = ConfigUpdateBody(params: self)
        return API.NonParseBodyCommand(method: .PUT, // MARK: Should be switched to ".PATCH" when server supports PATCH.
                                       path: .config,
                                       body: body) { (data) -> Bool in
            let updated = try ParseCoding.jsonDecoder().decode(BooleanResponse.self, from: data).result

            if updated {
                Self.updateKeychainIfNeeded(self)
            }
            return updated
        }
    }
}

internal struct ConfigUpdateBody<T>: ParseTypeable, Decodable where T: ParseConfig {
    let params: T
}

// MARK: Current
struct CurrentConfigContainer<T: ParseConfig>: Codable, Equatable {
    var currentConfig: T?
}

public extension ParseConfig {

    internal static var currentContainer: CurrentConfigContainer<Self>? {
        get {
            guard let configInMemory: CurrentConfigContainer<Self> =
                try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                #if !os(Linux) && !os(Android) && !os(Windows)
                    return try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
                #else
                    return nil
                #endif
            }
            return configInMemory
        }
        set {
            try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
            #if !os(Linux) && !os(Android) && !os(Windows)
            try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
            #endif
        }
    }

    internal static func updateKeychainIfNeeded(_ result: Self, deleting: Bool = false) {
        if !deleting {
            Self.current = result
        } else {
            Self.deleteCurrentContainerFromKeychain()
        }
    }

    internal static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #endif
    }

    /**
     Gets/Sets properties of the current config in the Keychain.

     - returns: Returns the latest `ParseConfig` on this device. If there is none, returns `nil`.
    */
    internal(set) static var current: Self? {
        get {
            return Self.currentContainer?.currentConfig
        }
        set {
            if Self.currentContainer == nil {
                Self.currentContainer = CurrentConfigContainer<Self>()
            }
            Self.currentContainer?.currentConfig = newValue
        }
    }
}
