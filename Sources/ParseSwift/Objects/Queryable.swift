//
//  Queryable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Queryable {
    associatedtype ResultType

    func find(options: API.Options) throws -> [ResultType]
    func first(options: API.Options) throws -> ResultType?
    func count(options: API.Options) throws -> Int
}

extension Queryable {
    func find() throws -> [ResultType] {
        return try find(options: [])
    }

    func first() throws -> ResultType? {
        return try first(options: [])
    }

    func count() throws -> Int {
        return try count(options: [])
    }
}
