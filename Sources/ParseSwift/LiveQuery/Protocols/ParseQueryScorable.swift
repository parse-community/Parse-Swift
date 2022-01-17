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
