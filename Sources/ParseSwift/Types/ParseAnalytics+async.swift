//
//  ParseAnalytics+async.swift
//  ParseAnalytics+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

#if os(iOS)
import UIKit
#endif

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension ParseAnalytics {

    // MARK: Aysnc/Await

    #if os(iOS)
    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push. Publishes when complete.
     
     - parameter launchOptions: The dictionary indicating the reason the application was
     launched, if any. This value can be found as a parameter to various
     `UIApplicationDelegate` methods, and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    static func trackAppOpened(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                               at date: Date? = nil,
                               options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            Self.trackAppOpened(launchOptions: launchOptions,
                                at: date,
                                options: options,
                                completion: continuation.resume)
        }
    }
    #endif

    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push. Publishes when complete.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    static func trackAppOpened(dimensions: [String: String]? = nil,
                               at date: Date? = nil,
                               options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            Self.trackAppOpened(dimensions: dimensions,
                                at: date,
                                options: options,
                                completion: continuation.resume)
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event. Publishes when complete.
  
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    func track(options: API.Options = []) async throws {
        _ = try await withCheckedThrowingContinuation { continuation in
            self.track(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
     Publishes when complete.
  
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: This method makes a copy of the current `ParseAnalytics` and then mutates
     it. You will not have access to the mutated analytic after calling this method.
     - throws: `ParseError`.
    */
    func track(dimensions: [String: String]?,
               at date: Date? = nil,
               options: API.Options = []) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            var analytic = self
            analytic.track(dimensions: dimensions,
                           at: date,
                           options: options,
                           completion: continuation.resume)
        }
    }
}

#endif
