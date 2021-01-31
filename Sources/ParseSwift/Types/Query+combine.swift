//
//  Query+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: Combine
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {

    // MARK: Queryable - Combine

    /**
     Finds objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findPublisher(options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.find(options: options,
                      completion: promise)
        }
    }

    /**
     Finds objects *asynchronously* and publishes when complete.
     - parameter explain: Used to toggle the information on the query plan.
     - parameter hint: String or Object of index that should be used when executing query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findPublisher(explain: Bool,
                       hint: String? = nil,
                       options: API.Options = []) -> Future<AnyCodable, ParseError> {
        Future { promise in
            self.find(explain: explain,
                      hint: hint,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Gets an object *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstPublisher(options: API.Options = []) -> Future<ResultType, ParseError> {
        Future { promise in
            self.first(options: options,
                       completion: promise)
        }
    }

    /**
     Gets an object *asynchronously* and publishes when complete.
     - parameter explain: Used to toggle the information on the query plan.
     - parameter hint: String or Object of index that should be used when executing query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstPublisher(explain: Bool,
                        hint: String? = nil,
                        options: API.Options = []) -> Future<AnyCodable, ParseError> {
        Future { promise in
            self.first(explain: explain,
                       hint: hint,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Count objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countPublisher(options: API.Options = []) -> Future<Int, ParseError> {
        Future { promise in
            self.count(options: options,
                       completion: promise)
        }
    }

    /**
     Count objects *asynchronously* and publishes when complete.
     - parameter explain: Used to toggle the information on the query plan.
     - parameter hint: String or Object of index that should be used when executing query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countPublisher(explain: Bool,
                        hint: String? = nil,
                        options: API.Options = []) -> Future<AnyCodable, ParseError> {
        Future { promise in
            self.count(explain: explain,
                       hint: hint,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Executes an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available and passed as one of the set of `options`.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func aggregatePublisher(_ pipeline: AggregateType,
                            options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.aggregate(pipeline,
                           options: options,
                           completion: promise)
        }
    }
}

#endif
