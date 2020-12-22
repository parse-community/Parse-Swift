//
//  Saveable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Saveable: Codable {
    associatedtype SavingType

    func save(options: API.Options) throws -> SavingType
    func save() throws -> SavingType
}

extension Saveable {
    public func save() throws -> SavingType {
        try save(options: [])
    }
}
