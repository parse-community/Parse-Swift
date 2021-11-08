//
//  Query+async.swift
//  Query+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension Query {

    // MARK: Async/Await

    /**
     Finds objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func find(options: API.Options = []) async throws -> [ResultType] {
        try await withCheckedThrowingContinuation { continuation in
            self.find(options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func findExplain<U: Decodable>(options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.findExplain(options: options,
                             completion: continuation.resume)
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query
     and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    func findAll(batchLimit: Int? = nil,
                 options: API.Options = []) async throws -> [ResultType] {
        try await withCheckedThrowingContinuation { continuation in
            self.findAll(batchLimit: batchLimit,
                         options: options,
                         completion: continuation.resume)
        }
    }

    /**
     Gets an object *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    func first(options: API.Options = []) async throws -> ResultType {
        try await withCheckedThrowingContinuation { continuation in
            self.first(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func firstExplain<U: Decodable>(options: API.Options = []) async throws -> U {
        try await withCheckedThrowingContinuation { continuation in
            self.firstExplain(options: options,
                              completion: continuation.resume)
        }
    }

    /**
     Count objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - throws: `ParseError`.
    */
    func count(options: API.Options = []) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            self.count(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter explain: Used to toggle the information on the query plan.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func countExplain<U: Decodable>(options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.countExplain(options: options,
                              completion: continuation.resume)
        }
    }

    /**
     Executes an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func aggregate(_ pipeline: [[String: Encodable]],
                   options: API.Options = []) async throws -> [ResultType] {
        try await withCheckedThrowingContinuation { continuation in
            self.aggregate(pipeline,
                           options: options,
                           completion: continuation.resume)
        }
    }

    /**
     Query plan information for executing an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
                                        options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.aggregateExplain(pipeline,
                           options: options,
                           completion: continuation.resume)
        }
    }

    /**
     Executes a distinct query *asynchronously* and publishes unique values when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func distinct(_ key: String,
                  options: API.Options = []) async throws -> [ResultType] {
        try await withCheckedThrowingContinuation { continuation in
            self.distinct(key,
                          options: options,
                          completion: continuation.resume)
        }
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and publishes unique values when complete.
     - requires: `.useMasterKey` has to be available.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: `ParseError`.
    */
    func distinctExplain<U: Decodable>(_ key: String,
                                       options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.distinctExplain(key,
                                 options: options,
                                 completion: continuation.resume)
        }
    }
}

#endif
