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
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findPublisher<U: Decodable>(explain: Bool,
                                     options: API.Options = []) -> Future<[U], ParseError> {
        Future { promise in
            self.find(explain: explain,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query
     and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    func findAllPublisher(batchLimit: Int? = nil,
                          options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.findAll(batchLimit: batchLimit,
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
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstPublisher<U: Decodable>(explain: Bool,
                                      options: API.Options = []) -> Future<U, ParseError> {
        Future { promise in
            self.first(explain: explain,
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
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countPublisher<U: Decodable>(explain: Bool,
                                      options: API.Options = []) -> Future<U, ParseError> {
        Future { promise in
            self.count(explain: explain,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Executes an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func aggregatePublisher(_ pipeline: [[String: AnyEncodable]],
                            options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.aggregate(pipeline,
                           options: options,
                           completion: promise)
        }
    }
}

#endif
