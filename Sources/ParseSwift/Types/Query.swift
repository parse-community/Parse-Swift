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
public struct QueryConstraint: Encodable, Equatable {
    enum Comparator: String, CodingKey, Encodable {
        case lessThan = "$lt"
        case lessThanOrEqualTo = "$lte"
        case greaterThan = "$gt"
        case greaterThanOrEqualTo = "$gte"
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
        case or = "$or" //swiftlint:disable:this identifier_name
        case and = "$and"
        case nor = "$nor"
        case relatedTo = "$relatedTo"
        case within = "$within"
        case geoWithin = "$geoWithin"
        case geoIntersects = "$geoIntersects"
        case maxDistance = "$maxDistance"
        case centerSphere = "$centerSphere"
        case box = "$box"
        case polygon = "$polygon"
        case point = "$point"
        case text = "$text"
        case search = "$search"
        case term = "$term"
        case regexOptions = "$options"
        case object = "object"
        case relativeTime = "$relativeTime"
    }

    var key: String
    var value: Encodable
    var comparator: Comparator?

    public func encode(to encoder: Encoder) throws {
        if let value = value as? Date {
            // Parse uses special case for date
            try value.parseRepresentation.encode(to: encoder)
        } else {
            try value.encode(to: encoder)
        }
    }

    public static func == (lhs: QueryConstraint, rhs: QueryConstraint) -> Bool {
        guard lhs.key == rhs.key,
              lhs.comparator == rhs.comparator else {
            return false
        }
        return lhs.value.isEqual(rhs.value)
    }
}

/**
 Add a constraint that requires that a key is greater than a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func > <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .greaterThan)
}

/**
 Add a constraint that requires that a key is greater than or equal to a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func >= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .greaterThanOrEqualTo)
}

/**
 Add a constraint that requires that a key is less than a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func < <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .lessThan)
}

/**
 Add a constraint that requires that a key is less than or equal to a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func <= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .lessThanOrEqualTo)
}

/**
 Add a constraint that requires that a key is equal to a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func == <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value)
}

/**
 Add a constraint that requires that a key is equal to a `ParseObject`.
 - parameter key: The key that the value is stored in.
 - parameter value: The `ParseObject` to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func == <T>(key: String, value: T) throws -> QueryConstraint where T: ParseObject {
    let constraint: QueryConstraint!
    do {
        constraint = try QueryConstraint(key: key, value: value.toPointer())
    } catch {
        guard let parseError = error as? ParseError else {
            throw ParseError(code: .unknownError,
                             message: error.localizedDescription)
        }
        throw parseError
    }
    return constraint
}

/**
 Add a constraint that requires that a key is not equal to a value.
 - parameter key: The key that the value is stored in.
 - parameter value: The value to compare.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func != <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .notEqualTo)
}

internal struct InQuery<T>: Encodable where T: ParseObject {
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

internal struct OrAndQuery<T>: Encodable where T: ParseObject {
    let query: Query<T>

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(query.where)
    }

    enum CodingKeys: String, CodingKey {
        case `where`
    }
}

internal struct QuerySelect<T>: Encodable where T: ParseObject {
    let query: InQuery<T>
    let key: String
}

/**
  Returns a `Query` that is the `or` of the passed in queries.
  - parameter queries: The list of queries to `or` together.
  - returns: An instance of `QueryConstraint`'s that are the `or` of the passed in queries.
 */
public func or <T>(queries: [Query<T>]) -> QueryConstraint where T: Encodable {
    let orQueries = queries.map { OrAndQuery(query: $0) }
    return QueryConstraint(key: QueryConstraint.Comparator.or.rawValue, value: orQueries)
}

/**
  Returns a `Query` that is the `nor` of the passed in queries.
  - parameter queries: The list of queries to `nor` together.
  - returns: An instance of `QueryConstraint`'s that are the `nor` of the passed in queries.
 */
public func nor <T>(queries: [Query<T>]) -> QueryConstraint where T: Encodable {
    let orQueries = queries.map { OrAndQuery(query: $0) }
    return QueryConstraint(key: QueryConstraint.Comparator.nor.rawValue, value: orQueries)
}

/**
   Constructs a Query that is the `and` of the passed in queries. For
    example:
    ~~~
    var compoundQueryConstraints = and(query1, query2, query3)
    ~~~
   will create a compoundQuery that is an and of the query1, query2, and
    query3.
    - parameter queries: The list of queries to `and` together.
    - returns: An instance of `QueryConstraint`'s that are the `and` of the passed in queries.
*/
public func and <T>(queries: [Query<T>]) -> QueryConstraint where T: Encodable {
    let andQueries = queries.map { OrAndQuery(query: $0) }
    return QueryConstraint(key: QueryConstraint.Comparator.and.rawValue, value: andQueries)
}

/**
 Add a constraint that requires that a key's value matches a `Query` constraint.
 - warning: This only works where the key's values are `ParseObject`s or arrays of `ParseObject`s.
 - parameter key: The key that the value is stored in.
 - parameter query: The query the value should match.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func == <T>(key: String, value: Query<T>) -> QueryConstraint {
    QueryConstraint(key: key, value: InQuery(query: value), comparator: .inQuery)
}

/**
 Add a constraint that requires that a key's value do not match a `Query` constraint.
 - warning: This only works where the key's values are `ParseObject`s or arrays of `ParseObject`s.
 - parameter key: The key that the value is stored in.
 - parameter query: The query the value should not match.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func != <T>(key: String, query: Query<T>) -> QueryConstraint {
    QueryConstraint(key: key, value: InQuery(query: query), comparator: .notInQuery)
}

/**
 Adds a constraint that requires that a key's value matches a value in another key
 in objects returned by a sub query.
 - parameter key: The key that contains the value that is being matched.
 - parameter queryKey: The key in objects in the returned by the sub query whose value should match.
 - parameter query: The query to run.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func matchesKeyInQuery <T>(key: String, queryKey: String, query: Query<T>) -> QueryConstraint {
    let select = QuerySelect(query: InQuery(query: query), key: queryKey)
    return QueryConstraint(key: key, value: select, comparator: .select)
}

/**
 Adds a constraint that requires that a key's value *not* match a value in another key
 in objects returned by a sub query.
 - parameter key: The key that contains the value that is being excluded.
 - parameter queryKey: The key in objects returned by the sub query whose value should match.
 - parameter query: The query to run.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func doesNotMatchKeyInQuery <T>(key: String, queryKey: String, query: Query<T>) -> QueryConstraint {
    let select = QuerySelect(query: InQuery(query: query), key: queryKey)
    return QueryConstraint(key: key, value: select, comparator: .dontSelect)
}

/**
  Add a constraint to the query that requires a particular key's object
  to be contained in the provided array.
  - parameter key: The key to be constrained.
  - parameter array: The possible values for the key's object.
  - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func containedIn <T>(key: String, array: [T]) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: array, comparator: .containedIn)
}

/**
  Add a constraint to the query that requires a particular key's object
  not be contained in the provided array.
  - parameter key: The key to be constrained.
  - parameter array: The list of values the key's object should not be.
  - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func notContainedIn <T>(key: String, array: [T]) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: array, comparator: .notContainedIn)
}

/**
  Add a constraint to the query that requires a particular key's array
  contains every element of the provided array.
  - parameter key: The key to be constrained.
  - parameter array: The possible values for the key's object.
  - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func containsAll <T>(key: String, array: [T]) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: array, comparator: .all)
}

/**
  Add a constraint to the query that requires a particular key's object
  to be contained by the provided array. Get objects where all array elements match.
  - parameter key: The key to be constrained.
  - parameter array: The possible values for the key's object.
  - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func containedBy <T>(key: String, array: [T]) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: array, comparator: .containedBy)
}

/**
 Add a constraint to the query that requires a particular key's time is related to a specified time. For example:
  ~~~
  let queryRelative = GameScore.query(relative("createdAt" < "12 days ago"))
  ~~~
 will create a relative query where `createdAt` is less than 12 days ago.
 - parameter constraint: The key to be constrained. Should be a Date field. The value is a
 reference time, e.g. "12 days ago". Currently only comparators supported are: <, <=, >=, and >=.
 - returns: The same instance of `QueryConstraint` as the receiver.
 - warning: This only works with Parse Servers using mongoDB.
 */
public func relative(_ constraint: QueryConstraint) -> QueryConstraint {
    QueryConstraint(key: constraint.key,
                    value: [QueryConstraint.Comparator.relativeTime.rawValue: AnyEncodable(constraint.value)],
                    comparator: constraint.comparator)
}

/**
 Add a constraint to the query that requires a particular key's coordinates (specified via `ParseGeoPoint`)
 be near a reference point. Distance is calculated based on angular distance on a sphere. Results will be sorted
 by distance from reference point.
 - parameter key: The key to be constrained.
 - parameter geoPoint: The reference point represented as a `ParseGeoPoint`.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func near(key: String, geoPoint: ParseGeoPoint) -> QueryConstraint {
    QueryConstraint(key: key, value: geoPoint, comparator: .nearSphere)
}

/**
 Add a constraint to the query that requires a particular key's coordinates (specified via `ParseGeoPoint`) be near
 a reference point and within the maximum distance specified (in radians). Distance is calculated based on
 angular distance on a sphere. Results will be sorted by distance (nearest to farthest) from the reference point.
 - parameter key: The key to be constrained.
 - parameter geoPoint: The reference point as a `ParseGeoPoint`.
 - parameter distance: Maximum distance in radians.
 - parameter sorted: `true` if results should be sorted by distance ascending, `false` is no sorting is required.
 Defaults to true.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinRadians(key: String,
                          geoPoint: ParseGeoPoint,
                          distance: Double,
                          sorted: Bool = true) -> [QueryConstraint] {
    if sorted {
        var constraints = [QueryConstraint(key: key, value: geoPoint, comparator: .nearSphere)]
        constraints.append(.init(key: key, value: distance, comparator: .maxDistance))
        return constraints
    } else {
        var constraints = [QueryConstraint(key: key, value: geoPoint, comparator: .centerSphere)]
        constraints.append(.init(key: key, value: distance, comparator: .geoWithin))
        return constraints
    }
}

/**
 Add a constraint to the query that requires a particular key's coordinates (specified via `ParseGeoPoint`)
 be near a reference point and within the maximum distance specified (in miles). Distance is calculated based
 on a spherical coordinate system. Results will be sorted by distance (nearest to farthest) from the reference point.
 - parameter key: The key to be constrained.
 - parameter geoPoint: The reference point represented as a `ParseGeoPoint`.
 - parameter distance: Maximum distance in miles.
 - parameter sorted: `true` if results should be sorted by distance ascending, `false` is no sorting is required.
 Defaults to true.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinMiles(key: String,
                        geoPoint: ParseGeoPoint,
                        distance: Double,
                        sorted: Bool = true) -> [QueryConstraint] {
    withinRadians(key: key,
                  geoPoint: geoPoint,
                  distance: (distance / ParseGeoPoint.earthRadiusMiles),
                  sorted: sorted)
}

/**
 Add a constraint to the query that requires a particular key's coordinates (specified via `ParseGeoPoint`)
 be near a reference point and within the maximum distance specified (in kilometers). Distance is calculated based
 on a spherical coordinate system. Results will be sorted by distance (nearest to farthest) from the reference point.
 - parameter key: The key to be constrained.
 - parameter geoPoint: The reference point represented as a `ParseGeoPoint`.
 - parameter distance: Maximum distance in kilometers.
 - parameter sorted: `true` if results should be sorted by distance ascending, `false` is no sorting is required.
 Defaults to true.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinKilometers(key: String,
                             geoPoint: ParseGeoPoint,
                             distance: Double,
                             sorted: Bool = true) -> [QueryConstraint] {
    withinRadians(key: key,
                  geoPoint: geoPoint,
                  distance: (distance / ParseGeoPoint.earthRadiusKilometers),
                  sorted: sorted)
}

/**
 Add a constraint to the query that requires a particular key's coordinates (specified via `ParseGeoPoint`) be
 contained within a given rectangular geographic bounding box.
 - parameter key: The key to be constrained.
 - parameter fromSouthWest: The lower-left inclusive corner of the box.
 - parameter toNortheast: The upper-right inclusive corner of the box.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinGeoBox(key: String, fromSouthWest southwest: ParseGeoPoint,
                         toNortheast northeast: ParseGeoPoint) -> QueryConstraint {
    let array = [southwest, northeast]
    let dictionary = [QueryConstraint.Comparator.box.rawValue: array]
    return .init(key: key, value: dictionary, comparator: .within)
}

/**
 Add a constraint to the query that requires a particular key's
 coordinates be contained within and on the bounds of a given polygon
 Supports closed and open (last point is connected to first) paths.

 Polygon must have at least 3 points.

 - parameter key: The key to be constrained.
 - parameter points: The polygon points as an Array of `ParseGeoPoint`'s.
 - warning: Requires Parse Server 2.5.0+.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinPolygon(key: String, points: [ParseGeoPoint]) -> QueryConstraint {
    let polygon = points.flatMap { [[$0.latitude, $0.longitude]]}
    let dictionary = [QueryConstraint.Comparator.polygon.rawValue: polygon]
    return .init(key: key, value: dictionary, comparator: .geoWithin)
}

/**
 Add a constraint to the query that requires a particular key's
 coordinates be contained within and on the bounds of a given polygon
 Supports closed and open (last point is connected to first) paths.

 - parameter key: The key to be constrained.
 - parameter polygon: The `ParsePolygon`.
 - warning: Requires Parse Server 2.5.0+.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinPolygon(key: String, polygon: ParsePolygon) -> QueryConstraint {
    let polygon = polygon.coordinates.flatMap { [[$0.latitude, $0.longitude]]}
    let dictionary = [QueryConstraint.Comparator.polygon.rawValue: polygon]
    return .init(key: key, value: dictionary, comparator: .geoWithin)
}

/**
 Add a constraint to the query that requires a particular key's
 coordinates contains a `ParseGeoPoint`.

 - parameter key: The key of the `ParsePolygon`.
 - parameter point: The `ParseGeoPoint` to check for containment.
 - warning: Requires Parse Server 2.6.0+.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func polygonContains(key: String, point: ParseGeoPoint) -> QueryConstraint {
    let dictionary = [QueryConstraint.Comparator.point.rawValue: point]
    return .init(key: key, value: dictionary, comparator: .geoIntersects)
}

/**
  Add a constraint for finding string values that contain a provided
  string using Full Text Search.
  - parameter key: The key to be constrained.
  - parameter text: The substring that the value must contain.
  - returns: The same instance of `Query` as the receiver.
 */
public func matchesText(key: String, text: String) -> QueryConstraint {
    let dictionary = [QueryConstraint.Comparator.search.rawValue: [QueryConstraint.Comparator.term.rawValue: text]]
    return .init(key: key, value: dictionary, comparator: .text)
}

/**
  Add a regular expression constraint for finding string values that match the provided regular expression.
  - warning: This may be slow for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter regex: The regular expression pattern to match.
  - parameter modifiers: Any of the following supported PCRE modifiers (defaults to nil):
  - `i` - Case insensitive search
  - `m` - Search across multiple lines of input
  - returns: The same instance of `Query` as the receiver.
 */
public func matchesRegex(key: String, regex: String, modifiers: String? = nil) -> QueryConstraint {

    if let modifiers = modifiers {
        let dictionary = [
            QueryConstraint.Comparator.regex.rawValue: regex,
            QueryConstraint.Comparator.regexOptions.rawValue: modifiers
        ]
        return .init(key: key, value: dictionary)
    } else {
        return .init(key: key, value: regex, comparator: .regex)
    }
}

private func regexStringForString(_ inputString: String) -> String {
    let escapedString = inputString.replacingOccurrences(of: "\\E", with: "\\E\\\\E\\Q")
    return "\\Q\(escapedString)\\E"
}

/**
  Add a constraint for finding string values that contain a provided substring.
  - warning: This will be slow for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter substring: The substring that the value must contain.
  - parameter modifiers: Any of the following supported PCRE modifiers (defaults to nil):
    - `i` - Case insensitive search
    - `m` - Search across multiple lines of input
  - returns: The same instance of `Query` as the receiver.
 */
public func containsString(key: String, substring: String, modifiers: String? = nil) -> QueryConstraint {
    let regex = regexStringForString(substring)
    return matchesRegex(key: key, regex: regex, modifiers: modifiers)
}

/**
  Add a constraint for finding string values that start with a provided prefix.
  This will use smart indexing, so it will be fast for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter prefix: The substring that the value must start with.
  - parameter modifiers: Any of the following supported PCRE modifiers (defaults to nil):
    - `i` - Case insensitive search
    - `m` - Search across multiple lines of input
  - returns: The same instance of `Query` as the receiver.
 */
public func hasPrefix(key: String, prefix: String, modifiers: String? = nil) -> QueryConstraint {
    let regex = "^\(regexStringForString(prefix))"
    return matchesRegex(key: key, regex: regex, modifiers: modifiers)
}

/**
  Add a constraint for finding string values that end with a provided suffix.
  - warning: This will be slow for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter suffix: The substring that the value must end with.
  - parameter modifiers: Any of the following supported PCRE modifiers (defaults to nil):
    - `i` - Case insensitive search
    - `m` - Search across multiple lines of input
  - returns: The same instance of `Query` as the receiver.
 */
public func hasSuffix(key: String, suffix: String, modifiers: String? = nil) -> QueryConstraint {
    let regex = "\(regexStringForString(suffix))$"
    return matchesRegex(key: key, regex: regex, modifiers: modifiers)
}

/**
  Add a constraint that requires a particular key exists.
  - parameter key: The key that should exist.
  - returns: The same instance of `Query` as the receiver.
 */
public func exists(key: String) -> QueryConstraint {
    .init(key: key, value: true, comparator: .exists)
}

/**
  Add a constraint that requires a key not exist.
  - parameter key: The key that should not exist.
  - returns: The same instance of `Query` as the receiver.
 */
public func doesNotExist(key: String) -> QueryConstraint {
    .init(key: key, value: false, comparator: .exists)
}

internal struct RelatedCondition <T>: Encodable where T: ParseObject {
    let object: Pointer<T>
    let key: String
}

/**
  Add a constraint that requires a key is related.
  - parameter key: The key that should be related.
  - parameter object: The object that should be related.
  - returns: The same instance of `Query` as the receiver.
 */
public func related <T>(key: String, object: Pointer<T>) -> QueryConstraint where T: ParseObject {
    let condition = RelatedCondition(object: object, key: key)
    return .init(key: QueryConstraint.Comparator.relatedTo.rawValue, value: condition)
}

internal struct QueryWhere: Encodable, Equatable {
    var constraints = [String: [QueryConstraint]]()

    mutating func add(_ constraint: QueryConstraint) {
        var existing = constraints[constraint.key] ?? []
        existing.append(constraint)
        constraints[constraint.key] = existing
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try constraints.forEach { (key, value) in
            try value.forEach { (constraint) in
                if constraint.comparator != nil {
                    var nestedContainer = container.nestedContainer(keyedBy: QueryConstraint.Comparator.self,
                                                      forKey: .key(key))
                    try constraint.encode(to: nestedContainer.superEncoder(forKey: constraint.comparator!))
                } else {
                    try container.encode(constraint, forKey: .key(key))
                }
            }
        }
    }
}

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
        var mutableQuery = self
        if mutableQuery.include != nil {
            mutableQuery.include = mutableQuery.include?.union(keys)
        } else {
            mutableQuery.include = Set(keys)
        }
        return mutableQuery
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
     - warning: Requires Parse Server > 4.5.0.
     */
    public func exclude(_ keys: String...) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.excludeKeys != nil {
            mutableQuery.excludeKeys = mutableQuery.excludeKeys?.union(keys)
        } else {
            mutableQuery.excludeKeys = Set(keys)
        }
        return mutableQuery
    }

    /**
     Exclude specific keys for a `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be excluded.
     - parameter keys: An array of keys to exclude in the result.
     - warning: Requires Parse Server > 4.5.0.
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
     - warning: Requires Parse Server > 4.5.0.
     */
    public func select(_ keys: String...) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.keys != nil {
            mutableQuery.keys = mutableQuery.keys?.union(keys)
        } else {
            mutableQuery.keys = Set(keys)
        }
        return mutableQuery
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to include in the result.
     - warning: Requires Parse Server > 4.5.0.
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
        var mutableQuery = self
        if mutableQuery.fields != nil {
            mutableQuery.fields = mutableQuery.fields?.union(keys)
        } else {
            mutableQuery.fields = Set(keys)
        }
        return mutableQuery
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
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a response of `Decodable` type.
    */
    public func findExplain<U: Decodable>(options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        return try findExplainCommand().execute(options: options)
    }

    /**
      Finds objects *asynchronously* and calls the given block with the results.

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
        findCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and calls the given block with the results.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
    */
    public func findExplain<U: Decodable>(options: API.Options = [],
                                          callbackQueue: DispatchQueue = .main,
                                          completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        findExplainCommand().executeAsync(options: options) { result in
            callbackQueue.async {
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
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a response of `Decodable` type.
    */
    public func firstExplain<U: Decodable>(options: API.Options = []) throws -> U {
        if limit == 0 {
            throw ParseError(code: .objectNotFound,
                             message: "Object not found on the server.")
        }
        return try firstExplainCommand().execute(options: options)
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
        firstCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
    */
    public func firstExplain<U: Decodable>(options: API.Options = [],
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
        firstExplainCommand().executeAsync(options: options) { result in
            callbackQueue.async {
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
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a response of `Decodable` type.
    */
    public func countExplain<U: Decodable>(options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        return try countExplainCommand().execute(options: options)
    }

    /**
      Counts objects *asynchronously* and calls the given block with the counts.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Int, ParseError>)`
    */
    public func count(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Int, ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success(0))
            }
            return
        }
        countCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and calls the given block with the counts.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
    */
    public func countExplain<U: Decodable>(options: API.Options = [],
                                           callbackQueue: DispatchQueue = .main,
                                           completion: @escaping (Result<[U], ParseError>) -> Void) {
        if limit == 0 {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        countExplainCommand().executeAsync(options: options) { result in
            callbackQueue.async {
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
            .executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Query plan information for  executing an aggregate query *synchronously*.
      - requires: `.useMasterKey` has to be available.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter pipeline: A pipeline of stages to process query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
    */
    public func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
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

        return try query.aggregateExplainCommand()
            .execute(options: options)
    }

    /**
     Query plan information for executing an aggregate query *asynchronously*.
        - requires: `.useMasterKey` has to be available.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: This hasn't been tested thoroughly.
    */
    public func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]],
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

        query.aggregateExplainCommand()
            .executeAsync(options: options) { result in
            callbackQueue.async {
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
            .executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Query plan information for executing an aggregate query *synchronously* and calls the given.
      - requires: `.useMasterKey` has to be available.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter key: A field to find distinct values.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
    */
    public func distinctExplain<U: Decodable>(_ key: String,
                                              options: API.Options = []) throws -> [U] {
        if limit == 0 {
            return [U]()
        }
        var options = options
        options.insert(.useMasterKey)
        return try distinctExplainCommand(key: key)
            .execute(options: options)
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and returns unique values.
        - requires: `.useMasterKey` has to be available.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter key: A field to find distinct values.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
        - warning: This hasn't been tested thoroughly.
    */
    public func distinctExplain<U: Decodable>(_ key: String,
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
        distinctExplainCommand(key: key)
            .executeAsync(options: options) { result in
            callbackQueue.async {
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
            try ParseCoding.jsonDecoder().decode(AnyResultsResponse.self, from: $0).results
        }
    }

    func firstExplainCommand<U: Decodable>() -> API.NonParseBodyCommand<Query<ResultType>, U> {
        var query = self
        query.limit = 1
        query.explain = true
        return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
            if let decoded: U = try ParseCoding.jsonDecoder().decode(AnyResultsResponse.self, from: $0).results.first {
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
            let decoded: [U] = try ParseCoding.jsonDecoder().decode(AnyResultsResponse.self, from: $0).results
            return decoded
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
        Query<Self>(constraints)
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
