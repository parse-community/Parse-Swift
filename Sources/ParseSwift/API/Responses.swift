//
//  Responses.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

internal struct SaveResponse: Decodable {
    var objectId: String
    var createdAt: Date
    var updatedAt: Date {
        return createdAt
    }

    func apply<T>(to object: T) -> T where T: ObjectType {
        var object = object
        object.objectId = objectId
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }
}

internal struct UpdateResponse: Decodable {
    var updatedAt: Date

    func apply<T>(to object: T) -> T where T: ObjectType {
        var object = object
        object.updatedAt = updatedAt
        return object
    }
}

internal struct FetchResponse: Decodable {
    var createdAt: Date
    var updatedAt: Date

    func apply<T>(to object: T) -> T where T: ObjectType {
        var object = object
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }
}
