//
//  Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

// MARK: Query
/**
  The `Query` class defines a query that is used to query for `ParseObject`s.
*/
public struct Query<T>: Encodable, Equatable where T: ParseObject {
    // interpolate as GET
    private let method: String = "GET"
    internal var limit: Int = 100
    internal var skip: Int = 0
    internal var keys: Set<String>?
    internal var include: Set<String>?
    internal var order: [Order]?
    internal var isCount: Bool?
    internal var explain: Bool?
    internal var hint: AnyEncodable?
    internal var `where` = QueryWhere()
    internal var excludeKeys: Set<String>?
    internal var readPreference: String?
    internal var includeReadPreference: String?
    internal var subqueryReadPreference: String?
    internal var distinct: String?
    internal var pipeline: [[String: AnyEncodable]]?
    internal var fields: Set<String>?

    struct AggregateBody<T>: Encodable where T: ParseObject {
        let pipeline: [[String: AnyEncodable]]?
        let hint: AnyEncodable?
        let explain: Bool?
        let includeReadPreference: String?

        init(query: Query<T>) {
            pipeline = query.pipeline
            hint = query.hint
            explain = query.explain
            includeReadPreference = query.includeReadPreference
        }
    }

    struct DistinctBody<T>: Encodable where T: ParseObject {
        let hint: AnyEncodable?
        let explain: Bool?
        let includeReadPreference: String?
        let distinct: String?

        init(query: Query<T>) {
            distinct = query.distinct
            hint = query.hint
            explain = query.explain
            includeReadPreference = query.includeReadPreference
        }
    }

    /**
      An enum that determines the order to sort the results based on a given key.

      - parameter key: The key to order by.
    */
    public enum Order: Encodable, Equatable {
        /// Sort in ascending order based on `key`.
        case ascending(String)
        /// Sort in descending order based on `key`.
        case descending(String)

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .ascending(let value):
                try container.encode(value)
            case .descending(let value):
                try container.encode("-\(value)")
            }
        }
    }

    /**
      Create an instance with a variadic amount constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     */
    public init(_ constraints: QueryConstraint...) {
        self.init(constraints)
    }

    /**
      Create an instance with an array of constraints.
     - parameter constraints: An array of `QueryConstraint`'s.
     */
    public init(_ constraints: [QueryConstraint]) {
        constraints.forEach({ self.where.add($0) })
    }

    public static func == (lhs: Query<T>, rhs: Query<T>) -> Bool {
        guard lhs.limit == rhs.limit,
              lhs.skip == rhs.skip,
              lhs.keys == rhs.keys,
              lhs.include == rhs.include,
              lhs.order == rhs.order,
              lhs.isCount == rhs.isCount,
              lhs.explain == rhs.explain,
              lhs.hint == rhs.hint,
              lhs.`where` == rhs.`where`,
              lhs.excludeKeys == rhs.excludeKeys,
              lhs.readPreference == rhs.readPreference,
              lhs.includeReadPreference == rhs.includeReadPreference,
              lhs.subqueryReadPreference == rhs.subqueryReadPreference,
              lhs.distinct == rhs.distinct,
              lhs.pipeline == rhs.pipeline,
              lhs.fields == rhs.fields else {
            return false
        }
        return true
    }

    /**
      Add any amount of variadic constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     */
    public func `where`(_ constraints: QueryConstraint...) -> Query<T> {
        self.`where`(constraints)
    }

    /**
      Add an array of variadic constraints.
     - parameter constraints: An array of zero or more `QueryConstraint`'s.
     */
    public func `where`(_ constraints: [QueryConstraint]) -> Query<T> {
        var mutableQuery = self
        constraints.forEach({ mutableQuery.where.add($0) })
        return mutableQuery
    }

    /**
      A limit on the number of objects to return. The default limit is `100`, with a
      maximum of 1000 results being returned at a time.

      - parameter value: `n` number of results to limit to.
      - note: If you are calling `find` with `limit = 1`, you may find it easier to use `first` instead.
    */
    public func limit(_ value: Int) -> Query<T> {
        var mutableQuery = self
        mutableQuery.limit = value
        return mutableQuery
    }

    /**
      The number of objects to skip before returning any.
      This is useful for pagination. Default is to skip zero results.
      - parameter value: `n` number of results to skip.
    */
    public func skip(_ value: Int) -> Query<T> {
        var mutableQuery = self
        mutableQuery.skip = value
        return mutableQuery
    }

    /**
      Adds a hint to force index selection.
      - parameter value: String or Object of index that should be used when executing query.
    */
    public func hint<U: Encodable>(_ value: U) -> Query<T> {
        var mutableQuery = self
        mutableQuery.hint = AnyEncodable(value)
        return mutableQuery
    }

    /**
      Changes the read preference that the backend will use when performing the query to the database.
      - parameter readPreference: The read preference for the main query.
      - parameter includeReadPreference: The read preference for the queries to include pointers.
      - parameter subqueryReadPreference: The read preference for the sub queries.
    */
    public func readPreference(_ readPreference: String?,
                               includeReadPreference: String? = nil,
                               subqueryReadPreference: String? = nil) -> Query<T> {
        var mutableQuery = self
        mutableQuery.readPreference = readPreference
        mutableQuery.includeReadPreference = includeReadPreference
        mutableQuery.subqueryReadPreference = subqueryReadPreference
        return mutableQuery
    }

    /**
     Make the query include `ParseObject`s that have a reference stored at the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: A variadic list of keys to load child `ParseObject`s for.
     */
    public func include(_ keys: String...) -> Query<T> {
        self.include(keys)
    }

    /**
     Make the query include `ParseObject`s that have a reference stored at the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to load child `ParseObject`s for.
     */
    public func include(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.include != nil {
            mutableQuery.include = mutableQuery.include?.union(keys)
        } else {
            mutableQuery.include = Set(keys)
        }
        return mutableQuery
    }

    /**
     Includes all nested `ParseObject`s one level deep.
     - warning: Requires Parse Server 3.0.0+.
     */
    public func includeAll() -> Query<T> {
        var mutableQuery = self
        mutableQuery.include = ["*"]
        return mutableQuery
    }

    /**
     Exclude specific keys for a `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be excluded.
     - parameter keys: A variadic list of keys include in the result.
     - warning: Requires Parse Server 5.0.0+.
     */
    public func exclude(_ keys: String...) -> Query<T> {
        self.exclude(keys)
    }

    /**
     Exclude specific keys for a `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be excluded.
     - parameter keys: An array of keys to exclude in the result.
     - warning: Requires Parse Server 5.0.0+.
    */
    public func exclude(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.excludeKeys != nil {
            mutableQuery.excludeKeys = mutableQuery.excludeKeys?.union(keys)
        } else {
            mutableQuery.excludeKeys = Set(keys)
        }
        return mutableQuery
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: A variadic list of keys include in the result.
     - warning: Requires Parse Server 5.0.0+.
     */
    public func select(_ keys: String...) -> Query<T> {
        self.select(keys)
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to include in the result.
     - warning: Requires Parse Server 5.0.0+.
     */
    public func select(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.keys != nil {
            mutableQuery.keys = mutableQuery.keys?.union(keys)
        } else {
            mutableQuery.keys = Set(keys)
        }
        return mutableQuery
    }

    /**
       An enum that determines the order to sort the results based on a given key.
      - parameter keys: An array of keys to order by.
    */
    public func order(_ keys: [Order]?) -> Query<T> {
        var mutableQuery = self
        mutableQuery.order = keys
        return mutableQuery
    }

    /**
     A variadic list of fields to receive when receiving a `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - warning: This is only for `ParseLiveQuery`.
     - parameter keys: A variadic list of fields to receive back instead of the whole `ParseObject`.
     */
    public func fields(_ keys: String...) -> Query<T> {
        self.fields(keys)
    }

    /**
     A list of fields to receive when receiving a `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - warning: This is only for `ParseLiveQuery`.
     - parameter keys: An array of fields to receive back instead of the whole `ParseObject`.
     */
    public func fields(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.fields != nil {
            mutableQuery.fields = mutableQuery.fields?.union(keys)
        } else {
            mutableQuery.fields = Set(keys)
        }
        return mutableQuery
    }

    /// The className of the `ParseObject` to query.
    public var className: String {
        return Self.className
    }

    /// The className of the `ParseObject` to query.
    public static var className: String {
        return T.className
    }

    var endpoint: API.Endpoint {
        return .objects(className: T.className)
    }

    enum CodingKeys: String, CodingKey {
        case `where`
        case method = "_method"
        case limit
        case skip
        case include
        case isCount = "count"
        case keys
        case order
        case explain
        case hint
        case excludeKeys
        case readPreference
        case includeReadPreference
        case subqueryReadPreference
        case distinct
        case pipeline
    }
}

// MARK: Queryable
extension Query: Queryable {

    public typealias ResultType = T

    /**
      Finds objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns an array of `ParseObject`s that were found.
    */
    public func find(options: API.Options = []) throws -> [ResultType] {
        if limit == 0 {
            return [ResultType]()
        }
        return try findCommand().execute(options: options)
    }

    /**
      Query plan information for finding objects *synchronously* based on the constructed query and
        sets an error if there was one.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - returns: Returns a response of `Decodable` type.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func findExplain<U: Decodable>(usingMongoDB: Bool = false,
                                          options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        if !usingMongoDB {
            return try findExplainCommand().execute(options: options)
        } else {
            return try findExplainMongoCommand().execute(options: options)
        }
    }

    /**
      Finds objects *asynchronously* and returns a completion block with the results.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`.
    */
    public func find(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        findCommand().executeAsync(options: options,
                                   callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and returns a completion block with the results.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func findExplain<U: Decodable>(usingMongoDB: Bool = false,
                                          options: API.Options = [],
                                          callbackQueue: DispatchQueue = .main,
                                          completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        if !usingMongoDB {
            findExplainCommand().executeAsync(options: options,
                                              callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } else {
            findExplainMongoCommand().executeAsync(options: options,
                                                   callbackQueue: callbackQueue) { result in
                completion(result)
            }
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query.
        
      - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
         is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
         Defaults to 50.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    public func findAll(batchLimit limit: Int? = nil,
                        options: API.Options = [],
                        callbackQueue: DispatchQueue = .main,
                        completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        if self.limit == 0 {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        if order != nil || skip > 0 || self.limit != 100 {
            let error = ParseError(code: .unknownError,
                             message: "Cannot iterate on a query with sort, skip, or limit.")
            completion(.failure(error))
            return
        }
        let uuid = UUID()
        let queue = DispatchQueue(label: "com.parse.findAll.\(uuid)",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.sync {

            var query = self
                .order([.ascending("objectId")])
            query.limit = limit ?? ParseConstants.batchLimit
            var results = [ResultType]()
            var finished = false

            while !finished {
                do {
                    let currentResults = try query.findCommand().execute(options: options)
                    results.append(contentsOf: currentResults)
                    if currentResults.count >= query.limit {
                        guard let lastObjectId = results[results.count - 1].objectId else {
                            throw ParseError(code: .unknownError, message: "Last object should have an id.")
                        }
                        query.where.add("objectId" > lastObjectId)
                    } else {
                        finished = true
                    }
                } catch {
                    callbackQueue.async {
                        guard let parseError = error as? ParseError else {
                            completion(.failure(ParseError(code: .unknownError,
                                                           message: error.localizedDescription)))
                            return
                        }
                        completion(.failure(parseError))
                    }
                    return
                }
            }

            callbackQueue.async {
                completion(.success(results))
            }
        }
    }

    /**
      Gets an object *synchronously* based on the constructed query and sets an error if any occurred.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a `ParseObject`.
    */
    public func first(options: API.Options = []) throws -> ResultType {
        if limit == 0 {
            throw ParseError(code: .objectNotFound,
                             message: "Object not found on the server.")
        }
        return try firstCommand().execute(options: options)
    }

    /**
     Query plan information for getting an object *synchronously* based on the
     constructed query and sets an error if any occurred.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - returns: Returns a response of `Decodable` type.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func firstExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = []) throws -> U {
        if limit == 0 {
            throw ParseError(code: .objectNotFound,
                             message: "Object not found on the server.")
        }
        if !usingMongoDB {
            return try firstExplainCommand().execute(options: options)
        } else {
            return try firstExplainMongoCommand().execute(options: options)
        }
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<ParseObject, ParseError>)`.
    */
    public func first(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<ResultType, ParseError>) -> Void) {
        if limit == 0 {
            let error = ParseError(code: .objectNotFound,
                                   message: "Object not found on the server.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        firstCommand().executeAsync(options: options,
                                    callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and returns a completion block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func firstExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = [],
                                           callbackQueue: DispatchQueue = .main,
                                           completion: @escaping (Result<U, ParseError>) -> Void) {
        if limit == 0 {
            let error = ParseError(code: .objectNotFound,
                                   message: "Object not found on the server.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        if !usingMongoDB {
            firstExplainCommand().executeAsync(options: options,
                                               callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } else {
            firstExplainMongoCommand().executeAsync(options: options,
                                                    callbackQueue: callbackQueue) { result in
                completion(result)
            }
        }
    }

    /**
      Counts objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - returns: Returns the number of `ParseObject`s that match the query, or `-1` if there is an error.
    */
    public func count(options: API.Options = []) throws -> Int {
        if limit == 0 {
            return 0
        }
        return try countCommand().execute(options: options)
    }

    /**
     Query plan information for counting objects *synchronously* based on the
     constructed query and sets an error if there was one.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - returns: Returns a response of `Decodable` type.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func countExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        if !usingMongoDB {
            return try countExplainCommand().execute(options: options)
        } else {
            return try countExplainMongoCommand().execute(options: options)
        }
    }

    /**
      Counts objects *asynchronously* and returns a completion block with the count.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Int, ParseError>)`
    */
    public func count(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Int, ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success(0))
            }
            return
        }
        countCommand().executeAsync(options: options,
                                    callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and returns a completion block with the count.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func countExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = [],
                                           callbackQueue: DispatchQueue = .main,
                                           completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        if !usingMongoDB {
            countExplainCommand().executeAsync(options: options,
                                               callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } else {
            countExplainMongoCommand().executeAsync(options: options,
                                                    callbackQueue: callbackQueue) { result in
                completion(result)
            }
        }
    }

    /**
     Finds objects *asynchronously* and returns a completion block with the results which include
     the total number of objects satisfying this query, despite limits/skip. Might be useful for pagination.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<([ResultType], Int), ParseError>)`
    */
    public func withCount(options: API.Options = [],
                          callbackQueue: DispatchQueue = .main,
                          completion: @escaping (Result<([ResultType], Int), ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success(([], 0)))
            }
            return
        }
        withCountCommand().executeAsync(options: options,
                                        callbackQueue: callbackQueue) { result in
            completion(result)
        }
    }

    /**
     Query plan information for withCount objects *asynchronously* and a completion block with the results.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func withCountExplain<U: Decodable>(usingMongoDB: Bool = false,
                                               options: API.Options = [],
                                               callbackQueue: DispatchQueue = .main,
                                               completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        if !usingMongoDB {
            withCountExplainCommand().executeAsync(options: options,
                                                   callbackQueue: callbackQueue) { result in
                completion(result)
            }
        } else {
            withCountExplainMongoCommand().executeAsync(options: options,
                                                        callbackQueue: callbackQueue) { result in
                completion(result)
            }
        }
    }

    /**
     Executes an aggregate query *synchronously*.
      - requires: `.useMasterKey` has to be available.
      - parameter pipeline: A pipeline of stages to process query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
    */
    public func aggregate(_ pipeline: [[String: Encodable]],
                          options: API.Options = []) throws -> [ResultType] {
        if limit == 0 {
            return [ResultType]()
        }
        var options = options
        options.insert(.useMasterKey)

        var updatedPipeline = [[String: AnyEncodable]]()
        pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyEncodable($0.value)] } }

        guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`),
            let whereString = String(data: encoded, encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Can't decode where to String.")
        }
        var query = self
        query.`where` = QueryWhere()

        if whereString != "{}" {
            var finishedPipeline = [["match": AnyEncodable(whereString)]]
            finishedPipeline.append(contentsOf: updatedPipeline)
            query.pipeline = finishedPipeline
        } else {
            query.pipeline = updatedPipeline
        }

        return try query.aggregateCommand()
            .execute(options: options)
    }

    /**
      Executes an aggregate query *asynchronously*.
        - requires: `.useMasterKey` has to be available.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: This hasn't been tested thoroughly.
    */
    public func aggregate(_ pipeline: [[String: Encodable]],
                          options: API.Options = [],
                          callbackQueue: DispatchQueue = .main,
                          completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        var options = options
        options.insert(.useMasterKey)

        var updatedPipeline = [[String: AnyEncodable]]()
        pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyEncodable($0.value)] } }

        guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`),
            let whereString = String(data: encoded, encoding: .utf8) else {
            let error = ParseError(code: .unknownError, message: "Can't decode where to String.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }

        var query = self
        query.`where` = QueryWhere()

        if whereString != "{}" {
            var finishedPipeline = [["match": AnyEncodable(whereString)]]
            finishedPipeline.append(contentsOf: updatedPipeline)
            query.pipeline = finishedPipeline
        } else {
            query.pipeline = updatedPipeline
        }

        query.aggregateCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue) { result in
                completion(result)
        }
    }

    /**
     Query plan information for  executing an aggregate query *synchronously*.
      - requires: `.useMasterKey` has to be available.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter pipeline: A pipeline of stages to process query.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - returns: Returns the `ParseObject`s that match the query.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
                                               usingMongoDB: Bool = false,
                                               options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        var options = options
        options.insert(.useMasterKey)

        var updatedPipeline = [[String: AnyEncodable]]()
        pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyEncodable($0.value)] } }

        guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`),
            let whereString = String(data: encoded, encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Can't decode where to String.")
        }
        var query = self
        query.`where` = QueryWhere()

        if whereString != "{}" {
            var finishedPipeline = [["match": AnyEncodable(whereString)]]
            finishedPipeline.append(contentsOf: updatedPipeline)
            query.pipeline = finishedPipeline
        } else {
            query.pipeline = updatedPipeline
        }
        if !usingMongoDB {
            return try query.aggregateExplainCommand()
                .execute(options: options)
        } else {
            return try query.aggregateExplainMongoCommand()
                .execute(options: options)
        }
    }

    /**
     Query plan information for executing an aggregate query *asynchronously*.
        - requires: `.useMasterKey` has to be available.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
        `usingMongoDB` flag needs to be set for MongoDB users. See more
        [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
                                               usingMongoDB: Bool = false,
                                               options: API.Options = [],
                                               callbackQueue: DispatchQueue = .main,
                                               completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        var options = options
        options.insert(.useMasterKey)

        var updatedPipeline = [[String: AnyEncodable]]()
        pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyEncodable($0.value)] } }

        guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`),
            let whereString = String(data: encoded, encoding: .utf8) else {
            let error = ParseError(code: .unknownError, message: "Can't decode where to String.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }

        var query = self
        query.`where` = QueryWhere()

        if whereString != "{}" {
            var finishedPipeline = [["match": AnyEncodable(whereString)]]
            finishedPipeline.append(contentsOf: updatedPipeline)
            query.pipeline = finishedPipeline
        } else {
            query.pipeline = updatedPipeline
        }
        if !usingMongoDB {
            query.aggregateExplainCommand()
                .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                    completion(result)
            }
        } else {
            query.aggregateExplainMongoCommand()
                .executeAsync(options: options, callbackQueue: callbackQueue) { result in
                    completion(result)
            }
        }
    }

    /**
     Executes an aggregate query *synchronously* and calls the given.
      - requires: `.useMasterKey` has to be available.
      - parameter key: A field to find distinct values.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
    */
    public func distinct(_ key: String,
                         options: API.Options = []) throws -> [ResultType] {
        if limit == 0 {
            return [ResultType]()
        }
        var options = options
        options.insert(.useMasterKey)
        return try distinctCommand(key: key)
            .execute(options: options)
    }

    /**
     Executes a distinct query *asynchronously* and returns unique values.
        - requires: `.useMasterKey` has to be available.
        - parameter key: A field to find distinct values.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: This hasn't been tested thoroughly.
    */
    public func distinct(_ key: String,
                         options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        var options = options
        options.insert(.useMasterKey)
        distinctCommand(key: key)
            .executeAsync(options: options,
                          callbackQueue: callbackQueue) { result in
                completion(result)
        }
    }

    /**
     Query plan information for executing an aggregate query *synchronously* and calls the given.
      - requires: `.useMasterKey` has to be available.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter key: A field to find distinct values.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
       [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func distinctExplain<U: Decodable>(_ key: String,
                                              usingMongoDB: Bool = false,
                                              options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        var options = options
        options.insert(.useMasterKey)
        if !usingMongoDB {
            return try distinctExplainCommand(key: key)
                .execute(options: options)
        } else {
            return try distinctExplainMongoCommand(key: key)
                .execute(options: options)
        }
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and returns unique values.
        - requires: `.useMasterKey` has to be available.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter key: A field to find distinct values.
        - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
        - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
        `usingMongoDB` flag needs to be set for MongoDB users. See more
        [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func distinctExplain<U: Decodable>(_ key: String,
                                              usingMongoDB: Bool = false,
                                              options: API.Options = [],
                                              callbackQueue: DispatchQueue = .main,
                                              completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        var options = options
        options.insert(.useMasterKey)
        if !usingMongoDB {
            distinctExplainCommand(key: key)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    completion(result)
            }
        } else {
            distinctExplainMongoCommand(key: key)
                .executeAsync(options: options,
                              callbackQueue: callbackQueue) { result in
                    completion(result)
            }
        }
    }
}

extension Query {

    func findCommand() -> API.NonParseBodyCommand<Query<ResultType>, [ResultType]> {
        let query = self
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
        }
    }

    func firstCommand() -> API.NonParseBodyCommand<Query<ResultType>, ResultType> {
        var query = self
        query.limit = 1
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            if let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results.first {
                return decoded
            }
            throw ParseError(code: .objectNotFound,
                              message: "Object not found on the server.")
        }
    }

    func countCommand() -> API.NonParseBodyCommand<Query<ResultType>, Int> {
        var query = self
        query.limit = 1
        query.isCount = true
        return API.NonParseBodyCommand(method: .POST,
                                       path: query.endpoint,
                                       body: query) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).count ?? 0
        }
    }

    func withCountCommand() -> API.NonParseBodyCommand<Query<ResultType>, ([ResultType], Int)> {
        var query = self
        query.isCount = true
        return API.NonParseBodyCommand(method: .POST,
                                       path: query.endpoint,
                                       body: query) {
            let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0)
            return (decoded.results, decoded.count ?? 0)
        }
    }

    func aggregateCommand() -> API.NonParseBodyCommand<AggregateBody<ResultType>, [ResultType]> {
        let query = self
        let body = AggregateBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
        }
    }

    func distinctCommand(key: String) -> API.NonParseBodyCommand<DistinctBody<ResultType>, [ResultType]> {
        var query = self
        query.distinct = key
        let body = DistinctBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
        }
    }

    func findExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
        }
    }

    func firstExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, U> {
        var query = self
        query.limit = 1
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            if let decoded = try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results.first {
                return decoded
            }
            throw ParseError(code: .objectNotFound,
                             message: "Object not found on the server.")
        }
    }

    func countExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.limit = 1
        query.isCount = true
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
        }
    }

    func withCountExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.isCount = true
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
        }
    }

    func aggregateExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<AggregateBody<ResultType>, [U]> {
        var query = self
        query.explain = true
        let body = AggregateBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
        }
    }

    func distinctExplainCommand<U: Decodable>(key: String) -> API.NonParseBodyCommand<DistinctBody<ResultType>, [U]> {
        var query = self
        query.explain = true
        query.distinct = key
        let body = DistinctBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
        }
    }

    func findExplainMongoCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
        }
    }

    func firstExplainMongoCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, U> {
        var query = self
        query.limit = 1
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            do {
                return try ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results
            } catch {
                throw ParseError(code: .objectNotFound,
                                 message: "Object not found on the server. Error: \(error)")
            }
        }
    }

    func countExplainMongoCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.limit = 1
        query.isCount = true
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
        }
    }

    func withCountExplainMongoCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        var query = self
        query.isCount = true
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
        }
    }

    func aggregateExplainMongoCommand<U: Decodable>() -> API.NonParseBodyCommand<AggregateBody<ResultType>, [U]> {
        var query = self
        query.explain = true
        let body = AggregateBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
        }
    }

    // swiftlint:disable:next line_length
    func distinctExplainMongoCommand<U: Decodable>(key: String) -> API.NonParseBodyCommand<DistinctBody<ResultType>, [U]> {
        var query = self
        query.explain = true
        query.distinct = key
        let body = DistinctBody(query: query)
        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
            try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
        }
    }
}

// MARK: Query
public extension ParseObject {

    /**
      Create an instance with no constraints.
     - returns: An instance of query for easy chaining.
     */
    static func query() -> Query<Self> {
        Query<Self>()
    }

    /**
      Create an instance with a variadic amount constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     - returns: An instance of query for easy chaining.
     */
    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        Self.query(constraints)
    }

    /**
      Create an instance with an array of constraints.
     - parameter constraints: An array of `QueryConstraint`'s.
     - returns: An instance of query for easy chaining.
     */
    static func query(_ constraints: [QueryConstraint]) -> Query<Self> {
        Query<Self>(constraints)
    }
}

// MARK: ParseUser
extension Query where T: ParseUser {
    var endpoint: API.Endpoint {
        return .users
    }
}

// MARK: ParseInstallation
extension Query where T: ParseInstallation {
    var endpoint: API.Endpoint {
        return .installations
    }
}

// MARK: ParseSession
extension Query where T: ParseSession {
    var endpoint: API.Endpoint {
        return .sessions
    }
}

// MARK: ParseRole
extension Query where T: ParseRole {
    var endpoint: API.Endpoint {
        return .roles
    }
}

enum RawCodingKey: CodingKey {
    case key(String)
    var stringValue: String {
        switch self {
        case .key(let str):
            return str
        }
    }
    var intValue: Int? {
        fatalError()
    }
    init?(stringValue: String) {
        self = .key(stringValue)
    }
    init?(intValue: Int) {
        fatalError()
    }
}

// MARK: CustomDebugStringConvertible
extension Query: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "\(className)"
        }
        return "\(className) (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension Query: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}

// swiftlint:disable:this file_length
