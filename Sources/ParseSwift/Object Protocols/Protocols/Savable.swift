//
//  Savable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Savable: Encodable {
    associatedtype SavingType

    func save(options: API.Options) throws -> SavingType
    func save() throws -> SavingType
}

extension Savable {
    public func save() throws -> SavingType {
        try save(options: [])
    }
}
