//
//  QueryWhere.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/9/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

struct QueryWhere: Encodable, Equatable {
    var constraints = [String: Set<QueryConstraint>]()

    mutating func add(_ constraint: QueryConstraint) {
        var existing = constraints[constraint.key] ?? []
        existing.insert(constraint)
        constraints[constraint.key] = existing
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try constraints.forEach { (key, value) in
            try value.forEach { (constraint) in
                if let comparator = constraint.comparator {
                    var nestedContainer = container.nestedContainer(keyedBy: QueryConstraint.Comparator.self,
                                                                    forKey: .key(key))
                    try constraint.encode(to: nestedContainer.superEncoder(forKey: comparator))
                } else {
                    try container.encode(constraint, forKey: .key(key))
                }
            }
        }
    }
}
