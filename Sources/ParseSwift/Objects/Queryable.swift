//
//  Queryable.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Querying {
    associatedtype ResultType

    func find(options: API.Options) throws -> [ResultType]
    func first(options: API.Options) throws -> ResultType?
    func count(options: API.Options) throws -> Int
}

extension Querying {
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
