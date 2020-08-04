//
//  ObjectType+Batch.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public extension ObjectType {
    static func saveAll(_ objects: Self...) throws -> [(Result<Self, ParseError>)] {
        return try objects.saveAll()
    }

    static func saveAll(options: API.Options = [],
                        _ objects: Self...,
                        completion: @escaping (Result<[(Result<Self, ParseError>)], ParseError>) -> Void) {
        objects.saveAll(options: options, completion: completion)
    }
}

extension Sequence where Element: ObjectType {
    public func saveAll(options: API.Options = []) throws -> [(Result<Self.Element, ParseError>)] {
        let commands = map { $0.saveCommand() }
        return try API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .execute(options: options)
    }

    public func saveAll(options: API.Options = [], callbackQueue: DispatchQueue = .main,
                        completion: @escaping (Result<[(Result<Element, ParseError>)], ParseError>) -> Void) {
        let commands = map { $0.saveCommand() }
        API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .executeAsync(options: options, callbackQueue: callbackQueue, completion: completion)
    }
}
