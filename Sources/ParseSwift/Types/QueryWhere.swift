//
//  QueryWhere.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/9/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/// The **where** of a `Query`.
public struct QueryWhere: ParseTypeable {
    var constraints = [String: Set<QueryConstraint>]()

    mutating func add(_ constraint: QueryConstraint) {
        var existing = constraints[constraint.key] ?? []
        existing.insert(constraint)
        constraints[constraint.key] = existing
    }

    public func encode(to encoder: Encoder) throws {
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

public extension QueryWhere {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RawCodingKey.self)
        try container.allKeys.forEach { key in
            do {
                let pointer = try container.decode(PointerType.self, forKey: key)
                var constraint = QueryConstraint(key: key.stringValue)
                constraint.value = AnyCodable(pointer)
                self.add(constraint)
            } catch {
                do {
                    let nestedContainer = try container.nestedContainer(keyedBy: QueryConstraint.Comparator.self,
                                                                        forKey: key)
                    QueryConstraint.Comparator.allCases.forEach { comparator in
                        guard var constraint = try? nestedContainer.decode(QueryConstraint.self,
                                                                           forKey: comparator) else {
                            return
                        }
                        constraint.key = key.stringValue
                        self.add(constraint)
                    }
                } catch {
                    var constraint = try container.decode(QueryConstraint.self, forKey: key)
                    constraint.key = key.stringValue
                    self.add(constraint)
                }
            }
        }
    }
}
