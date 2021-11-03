//
//  ParseAnalytics.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

/**
  `ParseAnalytics` provides an interface to Parse's logging and analytics
 backend.
 
 - warning: For iOS 14.0, macOS 11.0, macCatalyst 14.0, tvOS 14.0, you
 will need to request tracking authorization for ParseAnalytics to work.
 See Apple's [documentation](https://developer.apple.com/documentation/apptrackingtransparency) for more for details.
 */
public struct ParseAnalytics: ParseType, Hashable {

    /// The name of the custom event to report to Parse as having happened.
    public let name: String

    /// Explicitly set the time associated with a given event. If not provided the server
    /// time will be used.
    public var at: Date? // swiftlint:disable:this identifier_name

    /// The dictionary of information by which to segment this event.
    public var dimensions: [String: String]?

    enum CodingKeys: String, CodingKey {
        case at, dimensions // swiftlint:disable:this identifier_name
    }

    /**
     Create an instance of ParseAnalytics for tracking.
     - parameter name: The name of the custom event to report to Parse as having happened.
     - parameter dimensions: The dictionary of information by which to segment this event. Defaults to `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the server
     time will be used. Defaults to `nil`.
     */
    public init (name: String,
                 dimensions: [String: String]? = nil,
                 at: Date? = nil) { // swiftlint:disable:this identifier_name
        self.name = name
        self.dimensions = dimensions
        self.at = at
    }

    #if os(iOS)
    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push.
     
     - parameter launchOptions: The dictionary indicating the reason the application was
     launched, if any. This value can be found as a parameter to various
     `UIApplicationDelegate` methods, and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static public func trackAppOpened(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                      at date: Date? = nil,
                                      options: API.Options = [],
                                      callbackQueue: DispatchQueue = .main,
                                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        #if canImport(AppTrackingTransparency)
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            if !ParseSwift.configuration.isTestingSDK {
                let status = ATTrackingManager.trackingAuthorizationStatus
                if status != .authorized {
                    callbackQueue.async {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "App tracking not authorized. Please request permission from user.")
                        completion(.failure(error))
                    }
                    return
                }
            }
        }
        #endif
        var userInfo: [String: String]?
        if let remoteOptions = launchOptions?[.remoteNotification] as? [String: String] {
            userInfo = remoteOptions
        }
        let appOppened = ParseAnalytics(name: "AppOpened",
                                        dimensions: userInfo,
                                        at: date)
        appOppened.saveCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    #endif

    /**
     Tracks *asynchronously* this application being launched with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static public func trackAppOpened(dimensions: [String: String]? = nil,
                                      at date: Date? = nil,
                                      options: API.Options = [],
                                      callbackQueue: DispatchQueue = .main,
                                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        #if canImport(AppTrackingTransparency)
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            if !ParseSwift.configuration.isTestingSDK {
                let status = ATTrackingManager.trackingAuthorizationStatus
                if status != .authorized {
                    callbackQueue.async {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "App tracking not authorized. Please request permission from user.")
                        completion(.failure(error))
                    }
                    return
                }
            }
        }
        #endif
        let appOppened = ParseAnalytics(name: "AppOpened",
                                        dimensions: dimensions,
                                        at: date)
        appOppened.saveCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func track(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        #if canImport(AppTrackingTransparency)
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            if !ParseSwift.configuration.isTestingSDK {
                let status = ATTrackingManager.trackingAuthorizationStatus
                if status != .authorized {
                    callbackQueue.async {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "App tracking not authorized. Please request permission from user.")
                        completion(.failure(error))
                    }
                    return
                }
            }
        }
        #endif
        self.saveCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public mutating func track(dimensions: [String: String]?,
                               at date: Date? = nil,
                               options: API.Options = [],
                               callbackQueue: DispatchQueue = .main,
                               completion: @escaping (Result<Void, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        #if canImport(AppTrackingTransparency)
        if #available(macOS 11.0, iOS 14.0, macCatalyst 14.0, tvOS 14.0, *) {
            if !ParseSwift.configuration.isTestingSDK {
                let status = ATTrackingManager.trackingAuthorizationStatus
                if status != .authorized {
                    callbackQueue.async {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "App tracking not authorized. Please request permission from user.")
                        completion(.failure(error))
                    }
                    return
                }
            }
        }
        #endif
        self.dimensions = dimensions
        self.at = date
        self.saveCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    internal func saveCommand() -> API.NonParseBodyCommand<Self, NoBody> {
        return API.NonParseBodyCommand(method: .POST,
                                       path: .event(event: name),
                                       body: self) { (data) -> NoBody in
            let parseError: ParseError!
            do {
                parseError = try ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            } catch {
                return try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
            }
            throw parseError
        }
    }
}

// MARK: CustomDebugStringConvertible
extension ParseAnalytics: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(name)"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseAnalytics: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}
