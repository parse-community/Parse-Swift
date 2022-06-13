//
//  ParseQueryScorable.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Conform to this protocol to add the required properties to your `ParseObject`
 for using `QueryConstraint.matchesText()` and `Query.sortByTextScore()`.
 - note: In order to sort you must use `Query.sortByTextScore()`.
   To retrieve the weight/rank, access the "score" property of your `ParseObject`.
 */
public protocol ParseQueryScorable {
    /**
     The weight/rank of a `QueryConstraint.matchesText()`.
    */
    var score: Double? { get }
}

// MARK: ParseQueryScorable
extension Query where T: ParseObject & ParseQueryScorable {
    /**
      Method to sort the full text search by text score.
      - parameter value: String or Object of index that should be used when executing query.
      - note: Your `ParseObject` should conform to `ParseQueryScorable` to retrieve
      the weight/rank via  the "score" property of your `ParseObject`.
    */
    public func sortByTextScore() -> Query<T> {
        var mutableQuery = self
        let ascendingScore = Order.ascending(QueryConstraint.Comparator.score.rawValue)
        if mutableQuery.order != nil {
            mutableQuery.order?.append(ascendingScore)
        } else {
            mutableQuery.order = [ascendingScore]
        }
        return mutableQuery.select(QueryConstraint.Comparator.score.rawValue)
    }
}
