//
//  Object+Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public extension ObjectType {
    static func find() throws -> [Self] {
        return try query().find()
    }

    static func query() -> Query<Self> {
        return Query<Self>()
    }

    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}
