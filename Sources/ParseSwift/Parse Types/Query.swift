//
//  Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
  All available query constraints.
*/
public struct QueryConstraint: Encodable {
    public enum Comparator: String, CodingKey, Encodable {
        case lessThan = "$lt"
        case lessThanOrEqualTo = "$lte"
        case greaterThan = "$gt"
        case greaterThanOrEqualTo = "$gte"
        case equals = "$eq"
        case notEqualTo = "$ne"
        case containedIn = "$in"
        case notContainedIn = "$nin"
        case containedBy = "$containedBy"
        case exists = "$exists"
        case select = "$select"
        case dontSelect = "$dontSelect"
        case all = "$all"
        case regex = "$regex"
        case inQuery = "$inQuery"
        case notInQuery = "$notInQuery"
        case nearSphere = "$nearSphere"
        case within = "$within"
        case geoWithin = "$geoWithin"
        case geoIntersects = "$geoIntersects"
        case maxDistance = "$maxDistance"
        case box = "$box"
        case polygon = "$polygon"
        case point = "$point"
        case search = "$search"
        case term = "$term"
        case regexOptions = "$options"
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

public func nearGeoPoint(key: String, point: GeoPoint) -> QueryConstraint {
    return QueryConstraint(key: key, value: point, comparator: .nearSphere)
}

//Needs to be fixed
public func nearGeoPoint(key: String, point: GeoPoint, withinRadians maxDistance: Double) -> QueryConstraint {
    return QueryConstraint(key: key, value: point, comparator: .nearSphere)
}

public func nearGeoPoint(key: String, point: GeoPoint, withinMiles maxDistance: Double) -> QueryConstraint {
    return nearGeoPoint(key: key, point: point, withinRadians: (maxDistance / GeoPoint.earthRadiusMiles))
}

public func nearGeoPoint(key: String, point: GeoPoint, withinKilometers maxDistance: Double) -> QueryConstraint {
    return nearGeoPoint(key: key, point: point, withinRadians: (maxDistance / GeoPoint.earthRadiusKilometers))
}

public func withinGeoBox(key: String, fromSouthWest southwest: GeoPoint, toNortheast northeast: GeoPoint) -> QueryConstraint {
    let array = [southwest, northeast]
    let dictionary = [QueryConstraint.Comparator.box: array]
    return .init(key: key, value: dictionary, comparator: .within)
}

public func withinPolygon(key: String, ponts: [GeoPoint]) -> QueryConstraint {
    let dictionary = [QueryConstraint.Comparator.polygon: ponts]
    return .init(key: key, value: dictionary, comparator: .within)
}

public func polygonContains(key: String, pont: GeoPoint) -> QueryConstraint {
    let dictionary = [QueryConstraint.Comparator.point: pont]
    return .init(key: key, value: dictionary, comparator: .geoIntersects)
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
The `ParseQuery` struct defines a query that is used to query for `ParseObject`s.
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
    private var explain: Bool? = false
    private var hint: AnyCodable?

    fileprivate var `where` = QueryWhere()

    /**
      An enum that determines the order to sort the results based on a given key.

      - parameter key: The key to order by.
    */
    public enum Order: Encodable {
        case ascending(String)
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

      - note: If you are calling `findObjects` with `limit = 1`, you may find it easier to use `first` instead.
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

    /**
      Investigates the query execution plan. Useful for optimizing queries.
    */
    public mutating func explain(_ value: Bool) -> Query<T> {
        self.explain = value
        return self
    }

    /**
      Investigates the query execution plan. Useful for optimizing queries.
    */
    public mutating func hint(_ value: AnyCodable) -> Query<T> {
        self.hint = value
        return self
    }

    /**
      The className of a `ParseObject` to query.
    */
    var className: String {
        return T.className
    }

    /**
      The className of a `ParseObject` to query.
    */
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
        case explain
        case hint
    }
}

extension Query: Queryable {

    public typealias ResultType = T

    /**
      Finds objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter options: A set of options used to save objects.
      - throws: An error of type `ParseError`.

      - returns: Returns an array of `ParseObject`s that were found.
    */
    public func find(options: API.Options = []) throws -> [ResultType] {
        let foundResults = try findCommand().execute(options: options)
        try? ResultType.updateKeychainIfNeeded(foundResults)
        return foundResults
    }

    /**
      Finds objects *asynchronously* and calls the given block with the results.

      - parameter options: A set of options used to save objects.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`
    */
    public func find(options: API.Options = [], callbackQueue: DispatchQueue,
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

      - parameter options: A set of options used to save objects.
      - throws: An error of type `ParseError`.

      - returns: Returns a `ParseObject`, or `nil` if none was found.
    */
    public func first(options: API.Options = []) throws -> ResultType? {
        let result = try firstCommand().execute(options: options)
        if let foundResult = result {
            try? ResultType.updateKeychainIfNeeded([foundResult])
        }
        return result
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.

      - parameter options: A set of options used to save objects.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `^(ParseObject *object, ParseError *error)`.
      `result` will be `nil` if `error` is set OR no object was found matching the query.
      `error` will be `nil` if `result` is set OR if the query succeeded, but found no results.
    */
    public func first(options: API.Options = [], callbackQueue: DispatchQueue,
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

      - parameter options: A set of options used to save objects.
      - throws: An error of type `ParseError`.

      - returns: Returns the number of `ParseObject`s that match the query, or `-1` if there is an error.
    */
    public func count(options: API.Options = []) throws -> Int {
        return try countCommand().execute(options: options)
    }

    /**
      Counts objects *asynchronously* and calls the given block with the counts.

      - parameter options: A set of options used to save objects.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `^(int count, ParseError *error)`
    */
    public func count(options: API.Options = [], callbackQueue: DispatchQueue,
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
