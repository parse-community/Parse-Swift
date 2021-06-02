//
//  ParseHealth+Combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseHealth {

    // MARK: Combine

    /**
     Calls the health check function *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func checkPublisher(options: API.Options = []) -> Future<String, ParseError> {
        Future { promise in
            Self.check(options: options,
                       completion: promise)
        }
    }
}
#endif
