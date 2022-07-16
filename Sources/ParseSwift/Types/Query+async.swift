//
//  Query+async.swift
//  Query+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

public extension Query {

    // MARK: Async/Await

    /**
     Finds objects *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
    */
    func find(options: API.Options = []) async throws -> [ResultType] {
        try await withCheckedThrowingContinuation { continuation in
            self.find(options: options,
                      completion: continuation.resume)
        }
    }

    /**
     Query plan information for finding objects *asynchronously*.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func findExplain<U: Decodable>(usingMongoDB: Bool = false,
                                   options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.findExplain(usingMongoDB: usingMongoDB,
                             options: options,
                             completion: continuation.resume)
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
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
     Gets an object *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The first `ParseObject`.
     - throws: An error of type `ParseError`.
    */
    func first(options: API.Options = []) async throws -> ResultType {
        try await withCheckedThrowingContinuation { continuation in
            self.first(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Query plan information for getting an object *asynchronously*.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func firstExplain<U: Decodable>(usingMongoDB: Bool = false,
                                    options: API.Options = []) async throws -> U {
        try await withCheckedThrowingContinuation { continuation in
            self.firstExplain(usingMongoDB: usingMongoDB,
                              options: options,
                              completion: continuation.resume)
        }
    }

    /**
     Count objects *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The count of `ParseObject`'s.
     - throws: An error of type `ParseError`.
    */
    func count(options: API.Options = []) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            self.count(options: options,
                       completion: continuation.resume)
        }
    }

    /**
     Query plan information for counting objects *asynchronously*.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func countExplain<U: Decodable>(usingMongoDB: Bool = false,
                                    options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.countExplain(usingMongoDB: usingMongoDB,
                              options: options,
                              completion: continuation.resume)
        }
    }

    /**
     Finds objects *asynchronously* and returns a tuple of the results which include
     the total number of objects satisfying this query, despite limits/skip. Might be useful for pagination.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The count of `ParseObject`'s.
     - throws: An error of type `ParseError`.
    */
    func withCount(options: API.Options = []) async throws -> ([ResultType], Int) {
        try await withCheckedThrowingContinuation { continuation in
            self.withCount(options: options,
                           completion: continuation.resume)
        }
    }

    /**
     Query plan information for withCount objects *asynchronously*.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func withCountExplain<U: Decodable>(usingMongoDB: Bool = false,
                                        options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.withCountExplain(usingMongoDB: usingMongoDB,
                                  options: options,
                                  completion: continuation.resume)
        }
    }

    /**
     Executes an aggregate query *asynchronously*.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
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
     Query plan information for executing an aggregate query *asynchronously*.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
                                        usingMongoDB: Bool = false,
                                        options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.aggregateExplain(pipeline,
                                  usingMongoDB: usingMongoDB,
                                  options: options,
                                  completion: continuation.resume)
        }
    }

    /**
     Executes a distinct query *asynchronously* and returns unique values when complete.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
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
     Query plan information for executing a distinct query *asynchronously* and returns unique values when complete.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter key: A field to find distinct values.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An array of ParseObjects.
     - throws: An error of type `ParseError`.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func distinctExplain<U: Decodable>(_ key: String,
                                       usingMongoDB: Bool = false,
                                       options: API.Options = []) async throws -> [U] {
        try await withCheckedThrowingContinuation { continuation in
            self.distinctExplain(key,
                                 usingMongoDB: usingMongoDB,
                                 options: options,
                                 completion: continuation.resume)
        }
    }
}

#endif
