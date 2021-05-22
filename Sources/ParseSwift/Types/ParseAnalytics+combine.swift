//
//  ParseAnalytics+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/20/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

#if os(iOS)
import UIKit
#endif

// MARK: Combine
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseAnalytics {

    // MARK: Check - Combine

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
    */
    static func trackAppOpenedPublisher(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                        at date: Date? = nil,
                                        options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.trackAppOpened(launchOptions: launchOptions,
                                at: date,
                                options: options,
                                completion: promise)
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
    */
    static func trackAppOpenedPublisher(dimensions: [String: String]? = nil,
                                        at date: Date? = nil,
                                        options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.trackAppOpened(dimensions: dimensions,
                                at: date,
                                options: options,
                                completion: promise)
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
    */
    func trackPublisher(dimensions: [String: String]? = nil,
                        at date: Date? = nil,
                        options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.track(dimensions: dimensions,
                       at: date,
                       options: options,
                       completion: promise)
        }
    }
}
#endif
