//
//  Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
public protocol Querying {
    associatedtype ResultType
    func find(options: API.Option, callback: @escaping (([ResultType]?, Error?) -> Void)) -> Cancellable
    func first(options: API.Option, callback: @escaping ((ResultType?, Error?) -> Void)) -> Cancellable
    func count(options: API.Option, callback: @escaping ((Int?, Error?) -> Void)) -> Cancellable
}

extension Querying {
    func find(callback: @escaping (([ResultType]?, Error?) -> Void)) -> Cancellable {
        return find(callback: callback)
    }
    func first(callback: @escaping ((ResultType?, Error?) -> Void)) -> Cancellable {
        return first(callback: callback)
    }
    func count(callback: @escaping ((Int?, Error?) -> Void)) -> Cancellable {
        return count(callback: callback)
    }
}

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

private struct InQuery<T>: Encodable where T: ObjectType {
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
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try _constraints.forEach { (key, value) in
            var c = container.nestedContainer(keyedBy: QueryConstraint.Comparator.self,
                                              forKey: .key(key))
            try value.forEach { (constraint) in
                try constraint.encode(to: c.superEncoder(forKey: constraint.comparator))
            }
        }
    }
}

public struct Query<T>: Encodable where T: ObjectType {
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

    public mutating func limit(_ value: Int) -> Query<T> {
        self.limit = value
        return self
    }

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

    public func find(options: API.Option, callback: @escaping ([T]?, Error?) -> Void) -> Cancellable {
        return endpoint.makeRequest(method: .post, body: self) {(data, error) in
            if let data = data {
                do {
                    let results = try getDecoder().decode(FindResult<T>.self, from: data).results
                    callback(results, nil)
                } catch {
                    callback(nil, error)
                }
            } else if let error = error {
                callback(nil, error)
            } else {
                fatalError()
            }
        }
    }

    public func first(options: API.Option, callback: @escaping ((T?, Error?) -> Void)) -> Cancellable {
        var query = self
        query.limit = 1
        return endpoint.makeRequest(method: .post, body: query) {(data, error) in
            if let data = data {
                do {
                    let result = try getDecoder().decode(FindResult<T>.self, from: data).results.first
                    callback(result, nil)
                } catch {
                    callback(nil, error)
                }
            } else if let error = error {
                callback(nil, error)
            } else {
                fatalError()
            }
        }
    }

    public func count(options: API.Option, callback: @escaping ((Int?, Error?) -> Void)) -> Cancellable {
        var query = self
        query.isCount = true
        query.limit = 1
        return endpoint.makeRequest(method: .post, body: query) {(data, error) in
            if let data = data {
                do {
                    let count = try getDecoder().decode(FindResult<T>.self, from: data).count ?? 0
                    callback(count, nil)
                } catch {
                    callback(nil, error)
                }
            } else if let error = error {
                callback(nil, error)
            } else {
                fatalError()
            }
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
