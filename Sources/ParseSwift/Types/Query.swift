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
    public enum Comparator: String, CodingKey, Encodable {
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
            // Special case for date... Not sure why encoder don't like
            try value.parseRepresentation.encode(to: encoder)
        } else {
            try value.encode(to: encoder)
        }
    }

    /// - warning: Doesn't compare "value"
    public static func == (lhs: QueryConstraint, rhs: QueryConstraint) -> Bool {
        guard lhs.key == rhs.key,
              lhs.comparator == rhs.comparator else {
            return false
        }
        return true
    }
}

public func > <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .greaterThan)
}

public func >= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .greaterThanOrEqualTo)
}

public func < <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .lessThan)
}

public func <= <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value, comparator: .lessThanOrEqualTo)
}

public func == <T>(key: String, value: T) -> QueryConstraint where T: Encodable {
    QueryConstraint(key: key, value: value)
}

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
  - parameter queries: The list of queries to or together.
  - returns: An instance of `QueryConstraint`'s that are the `or` of the passed in queries.
 */
public func or <T>(queries: [Query<T>]) -> QueryConstraint where T: Encodable {
    let orQueries = queries.map { OrAndQuery(query: $0) }
    return QueryConstraint(key: QueryConstraint.Comparator.or.rawValue, value: orQueries)
}

/**
  Returns a `Query` that is the `nor` of the passed in queries.
  - parameter queries: The list of queries to `or` together.
  - returns: An instance of `QueryConstraint`'s that are the `nor` of the passed in queries.
 */
public func nor <T>(queries: [Query<T>]) -> QueryConstraint where T: Encodable {
    let orQueries = queries.map { OrAndQuery(query: $0) }
    return QueryConstraint(key: QueryConstraint.Comparator.nor.rawValue, value: orQueries)
}

/**
   Constructs a Query that is the AND of the passed in queries. For
    example:
    ~~~
    var compoundQueryConstraints = and(query1, query2, query3)
    ~~~
   will create a compoundQuery that is an and of the query1, query2, and
    query3.
    - parameter queries: The list of queries to AND.
    - returns: The query that is the AND of the passed in queries.
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
 - parameter key: The key that the value is stored.
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
 - parameter key: The key that the value is stored.
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
 Add a constraint to the query that requires a particular key's time is related to a specified time. E.g. "3 days ago".

 - parameter key: The key to be constrained. Should be a Date field.
 - parameter comparator: How the relative time should be compared. Currently only supports the
 $lt, $lte, $gt, and $gte operators.
 - parameter time: The reference time, e.g. "12 days ago".
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func relative(key: String, comparator: QueryConstraint.Comparator, time: String) -> QueryConstraint {
    QueryConstraint(key: key, value: [QueryConstraint.Comparator.relativeTime.rawValue: time], comparator: comparator)
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
    return withinRadians(key: key, geoPoint: geoPoint, distance: (distance / ParseGeoPoint.earthRadiusMiles))
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
    return withinRadians(key: key, geoPoint: geoPoint, distance: (distance / ParseGeoPoint.earthRadiusKilometers))
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
 (Requires parse-server@2.5.0)

 Polygon must have at least 3 points.

 - parameter key: The key to be constrained.
 - parameter points: The polygon points as an Array of `ParseGeoPoint`'s.
 - returns: The same instance of `QueryConstraint` as the receiver.
 */
public func withinPolygon(key: String, points: [ParseGeoPoint]) -> QueryConstraint {
    let dictionary = [QueryConstraint.Comparator.polygon.rawValue: points]
    return .init(key: key, value: dictionary, comparator: .geoWithin)
}

/**
 Add a constraint to the query that requires a particular key's
 coordinates that contains a `ParseGeoPoint`
 (Requires parse-server@2.6.0)

 - parameter key: The key to be constrained.
 - parameter point: The point the polygon contains `ParseGeoPoint`.

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
  - returns: The same instance of `Query` as the receiver.
 */
public func matchesRegex(key: String, regex: String) -> QueryConstraint {
    .init(key: key, value: regex, comparator: .regex)
}

/**
  Add a regular expression constraint for finding string values that match the provided regular expression.
  - warning: This may be slow for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter regex: The regular expression pattern to match.
  - parameter modifiers: Any of the following supported PCRE modifiers:
  - `i` - Case insensitive search
  - `m` - Search across multiple lines of input
  - returns: The same instance of `Query` as the receiver.
 */
public func matchesRegex(key: String, regex: String, modifiers: String) -> QueryConstraint {
    let dictionary = [
        QueryConstraint.Comparator.regex.rawValue: regex,
        QueryConstraint.Comparator.regexOptions.rawValue: modifiers
    ]
    return .init(key: key, value: dictionary)
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
  - returns: The same instance of `Query` as the receiver.
 */
public func containsString(key: String, substring: String) -> QueryConstraint {
    let regex = regexStringForString(substring)
    return matchesRegex(key: key, regex: regex)
}

/**
  Add a constraint for finding string values that start with a provided prefix.
  This will use smart indexing, so it will be fast for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter prefix: The substring that the value must start with.
  - returns: The same instance of `Query` as the receiver.
 */
public func hasPrefix(key: String, prefix: String) -> QueryConstraint {
    let regex = "^\(regexStringForString(prefix))"
    return matchesRegex(key: key, regex: regex)
}

/**
  Add a constraint for finding string values that end with a provided suffix.
  - warning: This will be slow for large datasets.
  - parameter key: The key that the string to match is stored in.
  - parameter suffix: The substring that the value must end with.
  - returns: The same instance of `Query` as the receiver.
 */
public func hasSuffix(key: String, suffix: String) -> QueryConstraint {
    let regex = "\(regexStringForString(suffix))$"
    return matchesRegex(key: key, regex: regex)
}

/**
  Add a constraint that requires a particular key exists.
  - parameter key: The key that should exist.
  - returns: The same instance of `Query` as the receiver.
 */
public func exists(key: String) -> QueryConstraint {
    return .init(key: key, value: true, comparator: .exists)
}

/**
  Add a constraint that requires a key not exist.
  - parameter key: The key that should not exist.
  - returns: The same instance of `Query` as the receiver.
 */
public func doesNotExist(key: String) -> QueryConstraint {
    return .init(key: key, value: false, comparator: .exists)
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

// MARK: Query
/**
  The `Query` class defines a query that is used to query for `ParseObject`s.
*/
public struct Query<T>: Encodable, Equatable where T: ParseObject {
    // interpolate as GET
    private let method: String = "GET"
    internal var limit: Int = 100
    internal var skip: Int = 0
    internal var keys: [String]?
    internal var include: [String]?
    internal var order: [Order]?
    internal var isCount: Bool?
    internal var explain: Bool?
    internal var hint: String?
    internal var `where` = QueryWhere()
    internal var excludeKeys: [String]?
    internal var readPreference: String?
    internal var includeReadPreference: String?
    internal var subqueryReadPreference: String?
    internal var distinct: String?
    internal var fields: [String]?

    /**
      An enum that determines the order to sort the results based on a given key.

      - parameter key: The key to order by.
    */
    public enum Order: Encodable, Equatable {
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
              lhs.subqueryReadPreference == rhs.subqueryReadPreference else {
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
     - parameter keys: A variadic list of keys to load child `ParseObject`s for.
     */
    public func include(_ keys: String...) -> Query<T> {
        var mutableQuery = self
        mutableQuery.include = keys
        return mutableQuery
    }

    /**
     Make the query include `ParseObject`s that have a reference stored at the provided keys.
     - parameter keys: An array of keys to load child `ParseObject`s for.
     */
    public func include(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        mutableQuery.include = keys
        return mutableQuery
    }

    /**
     Includes all nested `ParseObject`s.
     - warning: Requires Parse Server 3.0.0+
     */
    public func includeAll() -> Query<T> {
        var mutableQuery = self
        mutableQuery.include = ["*"]
        return mutableQuery
    }

    /**
     Exclude specific keys for a `ParseObject`. Default is to nil.
      - parameter keys: An arrays of keys to exclude.
    */
    public func exclude(_ keys: [String]?) -> Query<T> {
        var mutableQuery = self
        mutableQuery.excludeKeys = keys
        return mutableQuery
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: A variadic list of keys include in the result.
     */
    public func select(_ keys: String...) -> Query<T> {
        var mutableQuery = self
        mutableQuery.keys = keys
        return mutableQuery
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to include in the result.
     */
    public func select(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        mutableQuery.keys = keys
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
      Executes a distinct query and returns unique values. Default is to nil.
      - parameter keys: A distinct key.
    */
    public func distinct(_ key: String?) -> Query<T> {
        var mutableQuery = self
        mutableQuery.distinct = key
        return mutableQuery
    }

    /**
     A variadic list of fields to receive when receiving a `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     - warning: This is only for `ParseLiveQuery`.
     - parameter keys: A variadic list of fields to receive back instead of the whole `ParseObject`.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    public func fields(_ keys: String...) -> Query<T> {
        var mutableQuery = self
        mutableQuery.fields = keys
        return mutableQuery
    }

    /**
     A list of fields to receive when receiving a `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     - warning: This is only for `ParseLiveQuery`.
     - parameter keys: An array of fields to receive back instead of the whole `ParseObject`.
     */
    @available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
    public func fields(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        mutableQuery.fields = keys
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
    }
}

// MARK: Queryable
extension Query: Queryable {

    public typealias ResultType = T
    public typealias AggregateType = [[String: String]]

    /**
      Finds objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns an array of `ParseObject`s that were found.
    */
    public func find(options: API.Options = []) throws -> [ResultType] {
        try findCommand().execute(options: options)
    }

    /**
      Finds objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a dictionary of `AnyResultType` that is the JSON response of the query.
    */
    public func find(explain: Bool, hint: String? = nil, options: API.Options = []) throws -> AnyCodable {
        try findCommand(explain: explain, hint: hint).execute(options: options)
    }

    /**
      Finds objects *asynchronously* and calls the given block with the results.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`.
    */
    public func find(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        findCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
      Finds objects *asynchronously* and calls the given block with the results.

      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<AnyCodable, ParseError>)`.
    */
    public func find(explain: Bool, hint: String? = nil, options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<AnyCodable, ParseError>) -> Void) {
        findCommand(explain: explain, hint: hint).executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
      Gets an object *synchronously* based on the constructed query and sets an error if any occurred.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a `ParseObject`, or `nil` if none was found.
    */
    public func first(options: API.Options = []) throws -> ResultType? {
        try firstCommand().execute(options: options)
    }

    /**
      Gets an object *synchronously* based on the constructed query and sets an error if any occurred.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a dictionary of `AnyResultType` that is the JSON response of the query.
    */
    public func first(explain: Bool, hint: String? = nil, options: API.Options = []) throws -> AnyCodable {
        try firstCommand(explain: explain, hint: hint).execute(options: options)
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<ParseObject, ParseError>)`.
    */
    public func first(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<ResultType, ParseError>) -> Void) {
        firstCommand().executeAsync(options: options) { result in

            callbackQueue.async {
                switch result {
                case .success(let first):
                    guard let first = first else {
                        completion(.failure(ParseError(code: .objectNotFound,
                                                       message: "Object not found on the server.")))
                        return
                    }
                    completion(.success(first))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<ParseObject, ParseError>)`.
    */
    public func first(explain: Bool, hint: String? = nil, options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<AnyCodable, ParseError>) -> Void) {
        firstCommand(explain: explain, hint: hint).executeAsync(options: options) { result in
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
        try countCommand().execute(options: options)
    }

    /**
      Counts objects *synchronously* based on the constructed query and sets an error if there was one.

      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.

      - returns: Returns a dictionary of `AnyResultType` that is the JSON response of the query.
    */
    public func count(explain: Bool, hint: String? = nil, options: API.Options = []) throws -> AnyCodable {
        try countCommand(explain: explain, hint: hint).execute(options: options)
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
        countCommand().executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
      Counts objects *asynchronously* and calls the given block with the counts.
      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Int, ParseError>)`.
    */
    public func count(explain: Bool, hint: String? = nil, options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<AnyCodable, ParseError>) -> Void) {
        countCommand(explain: explain, hint: hint).executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    /**
     Executes an aggregate query *asynchronously* and calls the given.
      - requires: `.useMasterKey` has to be available and passed as one of the set of `options`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - throws: An error of type `ParseError`.
      - warning: This hasn't been tested thoroughly.
      - returns: Returns the `ParseObject`s that match the query.
    */
    public func aggregate(_ pipeline: AggregateType,
                          options: API.Options = []) throws -> [ResultType] {
        var options = options
        options.insert(.useMasterKey)

        let encoded = try ParseCoding.jsonEncoder()
            .encode(self.`where`)
        guard let whereString = String(data: encoded, encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Can't decode where to String.")
        }
        var updatedPipeline: AggregateType = pipeline
        if whereString != "{}" {
            updatedPipeline = [["match": whereString]]
            updatedPipeline.append(contentsOf: pipeline)
        }

        return try aggregateCommand(updatedPipeline)
            .execute(options: options)
    }

    /**
      Executes an aggregate query *asynchronously* and calls the given.
        - requires: `.useMasterKey` has to be available and passed as one of the set of `options`.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`.
        - warning: This hasn't been tested thoroughly.
    */
    public func aggregate(_ pipeline: AggregateType,
                          options: API.Options = [],
                          callbackQueue: DispatchQueue = .main,
                          completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)

        guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`),
            let whereString = String(data: encoded, encoding: .utf8) else {
            let error = ParseError(code: .unknownError, message: "Can't decode where to String.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        var updatedPipeline: AggregateType = pipeline
        if whereString != "{}" {
            updatedPipeline = [["match": whereString]]
            updatedPipeline.append(contentsOf: pipeline)
        }

        aggregateCommand(pipeline)
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
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
        }
    }

    func firstCommand() -> API.NonParseBodyCommand<Query<ResultType>, ResultType?> {
        var query = self
        query.limit = 1
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results.first
        }
    }

    func countCommand() -> API.NonParseBodyCommand<Query<ResultType>, Int> {
        var query = self
        query.limit = 1
        query.isCount = true
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).count ?? 0
        }
    }

    func findCommand(explain: Bool, hint: String?) -> API.NonParseBodyCommand<Query<ResultType>, AnyCodable> {
        var query = self
        query.explain = explain
        query.hint = hint
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            if let results = try JSONDecoder().decode(AnyResultsResponse.self, from: $0).results {
                return results
            }
            return AnyCodable()
        }
    }

    func firstCommand(explain: Bool, hint: String?) -> API.NonParseBodyCommand<Query<ResultType>, AnyCodable> {
        var query = self
        query.limit = 1
        query.explain = explain
        query.hint = hint
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            if let results = try JSONDecoder().decode(AnyResultsResponse.self, from: $0).results {
                return results
            }
            return AnyCodable()
        }
    }

    func countCommand(explain: Bool, hint: String?) -> API.NonParseBodyCommand<Query<ResultType>, AnyCodable> {
        var query = self
        query.limit = 1
        query.isCount = true
        query.explain = explain
        query.hint = hint
        return API.NonParseBodyCommand(method: .POST, path: endpoint, body: query) {
            if let results = try JSONDecoder().decode(AnyResultsResponse.self, from: $0).results {
                return results
            }
            return AnyCodable()
        }
    }

    func aggregateCommand(_ pipeline: AggregateType) -> API.NonParseBodyCommand<AggregateType, [ResultType]> {

        return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: pipeline) {
            try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
        }
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
// swiftlint:disable:this file_length
