//
//  ParseAnalytics+async.swift
//  ParseAnalytics+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

#if os(iOS)
import UIKit
#endif

public extension ParseAnalytics {

    // MARK: Aysnc/Await

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
     - throws: An error of type `ParseError`.
    */
    static func trackAppOpened(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                               at date: Date? = nil,
                               options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            Self.trackAppOpened(launchOptions: launchOptions,
                                at: date,
                                options: options,
                                completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }
    #endif

    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
    */
    static func trackAppOpened(dimensions: [String: String]? = nil,
                               at date: Date? = nil,
                               options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            Self.trackAppOpened(dimensions: dimensions,
                                at: date,
                                options: options,
                                completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event.
  
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
    */
    func track(options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.track(options: options,
                       completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
  
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
    */
    mutating func track(dimensions: [String: String]?,
                        at date: Date? = nil,
                        options: API.Options = []) async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.track(dimensions: dimensions,
                       at: date,
                       options: options,
                       completion: continuation.resume)
        }
        if case let .failure(error) = result {
            throw error
        }
    }
}

#endif
