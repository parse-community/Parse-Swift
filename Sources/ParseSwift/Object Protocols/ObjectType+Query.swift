//
//  Object+Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public extension ObjectType {
    public static func find(callback: @escaping ((Result<[Self]>) -> Void)) -> Cancellable {
        return query().find(callback: callback)
    }

    public static func query() -> Query<Self> {
        return Query<Self>()
    }

    public static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        return Query(constraints)
    }
}
