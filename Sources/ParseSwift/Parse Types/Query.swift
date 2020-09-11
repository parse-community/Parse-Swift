//
//  Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol Querying {
    associatedtype ResultType
    func find(options: API.Options) throws -> [ResultType]
    func first(options: API.Options) throws -> ResultType?
    func count(options: API.Options) throws -> Int
    func find(options: API.Options, callbackQueue: DispatchQueue,
              completion: @escaping (Result<[ResultType], ParseError>) -> Void)
    func first(options: API.Options, callbackQueue: DispatchQueue,
               completion: @escaping (Result<ResultType, ParseError>) -> Void)
    func count(options: API.Options, callbackQueue: DispatchQueue,
               completion: @escaping (Result<Int, ParseError>) -> Void)
}

extension Querying {
    func find() throws -> [ResultType] {
        return try find(options: [])
    }
    func first() throws -> ResultType? {
        return try first(options: [])
    }
    func count() throws -> Int {
        return try count(options: [])
    }
    func find(completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        find(options: [], callbackQueue: .main, completion: completion)
    }
    func first(completion: @escaping (Result<ResultType, ParseError>) -> Void) {
        first(options: [], callbackQueue: .main, completion: completion)
    }
    func count(completion: @escaping (Result<Int, ParseError>) -> Void) {
        count(options: [], callbackQueue: .main, completion: completion)
    }
}

/**
  All available query constraints.

*/
public struct QueryConstraint: Encodable {
    public enum Comparator: String, CodingKey {
        case lessThan = "$lt"
        case lessThanOrEqualTo = "$lte"
        case greaterThan = "$gt"
        case greaterThanOrEqualTo = "$gte"
        case equals = "$eq"
        case notEqualTo = "$neq"
        case containedIn = "$in"
        case notContainedIn = "$nin"
        case exists = "$exists"
        case select = "$select"
        case dontSelect = "$dontSelect"
        case all = "$all"
        case regex = "$regex"
        case inQuery = "$inQuery"
    }

    var key: String
    var value: Encodable
    var comparator: Comparator

    public func encode(to encoder: Encoder) throws {
        if let value = value as? Date {
            // Special case for date... Not sure why encoder don't like
            try value.parseRepresentation.encode(to: encoder)
        } else {
            try value.encode(to: encoder)
        }
    }
}

public func > <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    return QueryConstraint(key: key, value: value, comparator: .greaterThan)
}

public func >= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    return QueryConstraint(key: key, value: value, comparator: .greaterThanOrEqualTo)
}

public func < <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    return QueryConstraint(key: key, value: value, comparator: .lessThan)
}

public func <= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    return QueryConstraint(key: key, value: value, comparator: .lessThanOrEqualTo)
}

public func == <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    return QueryConstraint(key: key, value: value, comparator: .equals)
}

private struct InQuery<T>: Encodable where T: ParseObject {
    let query: Query<T>
    var className: String {
        return T.className
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(className, forKey: .className)
        try container.encode(query.where, forKey: .where)
    }

    enum CodingKeys: String, CodingKey {
        case `where`, className
    }
}

public func == <T>(key: String, value: Query<T>) -> QueryConstraint {
    return QueryConstraint(key: key, value: InQuery(query: value), comparator: .inQuery)
}

internal struct QueryWhere: Encodable {
    private var _constraints = [String: [QueryConstraint]]()

    mutating func add(_ constraint: QueryConstraint) {
        var existing = _constraints[constraint.key] ?? []
        existing.append(constraint)
        _constraints[constraint.key] = existing
    }

    // This only encodes the where...
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try _constraints.forEach { (key, value) in
            var nestedContainer = container.nestedContainer(keyedBy: QueryConstraint.Comparator.self,
                                              forKey: .key(key))
            try value.forEach { (constraint) in
                try constraint.encode(to: nestedContainer.superEncoder(forKey: constraint.comparator))
            }
        }
    }
}

/**
The `ParseQuery` protocol defines a query that is used to query for `ParseObject`s.
*/
public struct Query<T>: Encodable where T: ParseObject {
    // interpolate as GET
    private let method: String = "GET"
    private var limit: Int = 100
    private var skip: Int = 0
    private var keys: [String]?
    private var include: [String]?
    private var order: [Order]?
    private var isCount: Bool?

    fileprivate var `where` = QueryWhere()

    public enum Order: Encodable {
        /**
          Sort the results in *ascending* order with the given key.
          
          - parameter value: The key to order by.
        */
        case ascending(String)
        /**
          Additionally sort in *ascending* order by the given key.
          
          The previous keys provided will precedence over this key.
          
          - parameter value: The key to order by.
        */
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

    public init(_ constraints: QueryConstraint...) {
        self.init(constraints)
    }

    public init(_ constraints: [QueryConstraint]) {
        constraints.forEach({ self.where.add($0) })
    }

    public mutating func `where`(_ constraints: QueryConstraint...) -> Query<T> {
        constraints.forEach({ self.where.add($0) })
        return self
    }

    /**
      A limit on the number of objects to return. The default limit is `100`, with a
      maximum of 1000 results being returned at a time.
      
      - warning: If you are calling `findObjects` with `limit = 1`, you may find it easier to use `getFirst` instead.
    */
    public mutating func limit(_ value: Int) -> Query<T> {
        self.limit = value
        return self
    }

    /**
      The number of objects to skip before returning any.
    */
    public mutating func skip(_ value: Int) -> Query<T> {
        self.skip = value
        return self
    }

    var className: String {
        return T.className
    }

    static var className: String {
        return T.className
    }

    var endpoint: API.Endpoint {
        return .objects(className: className)
    }

    enum CodingKeys: String, CodingKey {
        case `where`
        case method = "_method"
        case limit
        case skip
        case isCount = "count"
        case keys
        case order
    }
}

extension Query: Querying {

    public typealias ResultType = T

    /**
      Finds objects *synchronously* based on the constructed query and sets an error if there was one.
    
      - parameter error: Pointer to an `ParseError` that will be set if necessary.
    
      - returns: Returns an array of `ParseObject` objects that were found.
    */
    public func find(options: API.Options) throws -> [ResultType] {
        let foundResults = try findCommand().execute(options: options)
        try? ResultType.updateKeychainIfNeeded(foundResults)
        return foundResults
    }

    /**
      Finds objects *asynchronously* and calls the given block with the results.
    
      - parameter block: The block to execute.
      
      It should have the following argument signature: `^(NSArray *objects, ParseError *error)`
    */
    public func find(options: API.Options, callbackQueue: DispatchQueue,
                     completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        findCommand().executeAsync(options: options, callbackQueue: callbackQueue) { results in
            if case .success(let foundResults) = results {
                try? ResultType.updateKeychainIfNeeded(foundResults)
            }
            completion(results)
        }
    }

    /**
      Gets an object *synchronously* based on the constructed query and sets an error if any occurred.
   
      - warning: This method mutates the query. It will reset the limit to `1`.
    
      - parameter error: Pointer to an `ParseError` that will be set if necessary.
    
      - returns: Returns a `ParseObject`, or `nil` if none was found.
    */
    public func first(options: API.Options) throws -> ResultType? {
        let result = try firstCommand().execute(options: options)
        if let foundResult = result {
            try? ResultType.updateKeychainIfNeeded([foundResult])
        }
        return result
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.
      
      - warning: This method mutates the query. It will reset the limit to `1`.
    
      - parameter block: The block to execute.
      It should have the following argument signature: `^(ParseObject *object, ParseError *error)`.
      `result` will be `nil` if `error` is set OR no object was found matching the query.
      `error` will be `nil` if `result` is set OR if the query succeeded, but found no results.
    */
    public func first(options: API.Options, callbackQueue: DispatchQueue,
                      completion: @escaping (Result<ResultType, ParseError>) -> Void) {
        firstCommand().executeAsync(options: options, callbackQueue: callbackQueue) { result in

            switch result {
            case .success(let first):
                guard let first = first else {
                    completion(.failure(ParseError(code: .unknownError, message: "unable to unwrap data") ))
                    return
                }
                try? ResultType.updateKeychainIfNeeded([first])
                completion(.success(first))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /**
      Counts objects *synchronously* based on the constructed query and sets an error if there was one.
      
      - parameter error Pointer to an `ParseError` that will be set if necessary.
      
      - returns: Returns the number of `ParseObject` objects that match the query, or `-1` if there is an error.
    */
    public func count(options: API.Options) throws -> Int {
        return try countCommand().execute(options: options)
    }

    /**
      Counts objects *asynchronously* and calls the given block with the counts.
      - parameter block: The block to execute.
      It should have the following argument signature: `^(int count, ParseError *error)`
    */
    public func count(options: API.Options, callbackQueue: DispatchQueue,
                      completion: @escaping (Result<Int, ParseError>) -> Void) {
        countCommand().executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }
}

private extension Query {
    private func findCommand() -> API.Command<Query<ResultType>, [ResultType]> {
        return API.Command(method: .POST, path: endpoint, body: self) {
            try ParseCoding.jsonDecoder().decode(FindResult<T>.self, from: $0).results
        }
    }

    private func firstCommand() -> API.Command<Query<ResultType>, ResultType?> {
        var query = self
        query.limit = 1
        return API.Command(method: .POST, path: endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(FindResult<T>.self, from: $0).results.first
        }
    }

    private func countCommand() -> API.Command<Query<ResultType>, Int> {
        var query = self
        query.limit = 1
        query.isCount = true
        return API.Command(method: .POST, path: endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(FindResult<T>.self, from: $0).count ?? 0
        }
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
