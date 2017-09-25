//
//  Object+Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public extension ObjectType {
    public static func find() throws -> [Self] {
        return try query().find()
    }

    public static func query() -> Query<Self> {
        return Query<Self>()
    }

    public static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}
