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

/**
 `ParseAnalytics` provides an interface to Parse's logging and analytics backend.
 */
public struct ParseAnalytics: ParseType, Hashable {

    /// The name of the custom event to report to Parse as having happened.
    public var name: String

    /// Explicitly set the time associated with a given event. If not provided the server
    /// time will be used.
    /// - warning: This will be deprecated in ParseSwift 5.5 in favor of `date`.
    public var at: Date? { // swiftlint:disable:this identifier_name
        get {
            date
        }
        set {
            date = newValue
        }
    }

    /// Explicitly set the time associated with a given event. If not provided the server
    /// time will be used.
    public var date: Date?

    /// The dictionary of information by which to segment this event.
    /// - warning: It is not recommended to set this directly.
    public var dimensions: [String: String]? {
        get {
            convertToString(dimensionsCodable)
        }
        set {
            dimensionsCodable = convertToAnyCodable(newValue)
        }
    }

    var dimensionsCodable: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case date = "at"
        case dimensions
        case name
    }

    /**
     Create an instance of ParseAnalytics for tracking.
     - parameter name: The name of the custom event to report to Parse as having happened.
     - parameter dimensions: The dictionary of information by which to segment this event. Defaults to `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the server
     time will be used. Defaults to `nil`.
     */
    public init (name: String,
                 dimensions: [String: Codable]? = nil,
                 at date: Date? = nil) {
        self.name = name
        self.dimensionsCodable = convertToAnyCodable(dimensions)
        self.date = date
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(dimensionsCodable, forKey: .dimensions)
        if !(encoder is _ParseEncoder) {
            try container.encode(name, forKey: .name)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.debugDescription == rhs.debugDescription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.debugDescription)
    }

    // MARK: Helpers
    func convertToAnyCodable(_ dimensions: [String: Codable]?) -> [String: AnyCodable]? {
        guard let dimensions = dimensions else {
            return nil
        }
        var convertedDimensions = [String: AnyCodable]()
        for (key, value) in dimensions {
            convertedDimensions[key] = AnyCodable(value)
        }
        return convertedDimensions
    }

    func convertToString(_ dimensions: [String: AnyCodable]?) -> [String: String]? {
        guard let dimensions = dimensions else {
            return nil
        }
        var convertedDimensions = [String: String]()
        for (key, value) in dimensions {
            convertedDimensions[key] = "\(value.value)"
        }
        return convertedDimensions
    }

    // MARK: Intents

    /**
     Set the dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event.
    */
    public mutating func setDimensions(_ dimensions: [String: Codable]) {
        dimensionsCodable = convertToAnyCodable(dimensions)
    }

    /**
     Update the dimensions with additional data or replace specific key value pairs.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event.
    */
    public mutating func updateDimensions(_ dimensions: [String: Codable]) {
        guard let convertedDimensions = convertToAnyCodable(dimensions) else {
            return
        }
        if dimensionsCodable == nil {
            dimensionsCodable = convertedDimensions
        } else {
            for (key, value) in convertedDimensions {
                dimensionsCodable?[key] = value
            }
        }
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
        var userInfo: [String: String]?
        if let remoteOptions = launchOptions?[.remoteNotification] as? [String: String] {
            userInfo = remoteOptions
        }
        let appOppened = ParseAnalytics(name: "AppOpened",
                                        dimensions: userInfo,
                                        at: date)
        appOppened.saveCommand().executeAsync(options: options,
                                              callbackQueue: callbackQueue) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    #endif

    /**
     Tracks *asynchronously* this application being launched with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event. Can be empty or `nil`.
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
        let appOppened = ParseAnalytics(name: "AppOpened",
                                        dimensions: dimensions,
                                        at: date)
        appOppened.saveCommand().executeAsync(options: options,
                                              callbackQueue: callbackQueue) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
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
        self.saveCommand().executeAsync(options: options,
                                        callbackQueue: callbackQueue) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event. Can be empty or `nil`.
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
        self.dimensionsCodable = convertToAnyCodable(dimensions)
        self.date = date
        self.saveCommand().executeAsync(options: options,
                                        callbackQueue: callbackQueue) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
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
