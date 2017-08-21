//
//  Synchronous.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

typealias ResultCapturing<T> = (Result<T>) -> Void
// Mark it private for now
private func await<T>(block: (@escaping ResultCapturing<T>) -> Void) throws -> T {
    let sema = DispatchSemaphore(value: 0)
    var r: Result<T>!
    block({
        r = $0
        sema.signal()
    })
    sema.wait()
    switch r! {
    case .success(let value):
        return value
    case .error(let error):
        throw error
    default:
        fatalError()
    }
}

public struct Synchronous<T> {
    let object: T
}

extension Synchronous where T: Fetching {
    public func fetch() throws -> T.FetchingType {
        return try await { done in
            _ = object.fetch(callback: done)
        }
    }
}

extension Synchronous where T: Saving {
    public func save() throws -> T.SavingType {
        return try await { done in
            _ = object.save(callback: done)
        }
    }
}

extension Synchronous where T: Querying {
    public func find() throws -> [T.ResultType] {
        return try await { done in
            _ = object.find(callback: done)
        }
    }
    public func first() throws -> T.ResultType? {
        return try await { done in
            _ = object.first(callback: done)
        }
    }
    public func count() throws -> Int {
        return try await { done in
            _ = object.count(callback: done)
        }
    }
}

public extension Saving {
    var sync: Synchronous<Self> {
        return Synchronous(object: self)
    }
}

public extension Fetching {
    var sync: Synchronous<Self> {
        return Synchronous(object: self)
    }
}

// Force implementation for ObjectType as Feching and Saving makes it ambiguous
public extension ObjectType {
    var sync: Synchronous<Self> {
        return Synchronous(object: self)
    }
}

public extension Query {
    var sync: Synchronous<Query> {
        return Synchronous(object: self)
    }
}
