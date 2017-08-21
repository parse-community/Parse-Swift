//
//  ObjectType+Equatable.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public func == <T>(lhs: T?, rhs: T?) -> Bool where T: ObjectType {
    guard let lhs = lhs, let rhs = rhs else { return false }
    return lhs == rhs
}

public func == <T>(lhs: T, rhs: T) -> Bool where T: ObjectType {
    return lhs.className == rhs.className && rhs.objectId == lhs.objectId
}
