//
//  Object+Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public extension ParseObjectType {
    public static func find() -> RESTCommand<Query<Self>, [Self]> {
        return query().find()
    }

    public static func query() -> Query<Self> {
        return Query<Self>()
    }

    public static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}
