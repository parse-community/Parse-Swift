//
//  ObjectType+Batch.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public extension ObjectType {
    public static func saveAll(_ objects: Self...) throws -> [(Self, ParseError?)] {
        return try objects.saveAll()
    }
}

extension Sequence where Element: ObjectType {
    public func saveAll(options: API.Options = []) throws -> [(Self.Element, ParseError?)] {
        let commands = map { $0.saveCommand() }
        return try API.Command<Self.Element, Self.Element>
                .batch(commands: commands)
                .execute(options: options)
    }
}
