//
//  Saveable.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Saving: Codable {
    associatedtype SavingType

    func save(options: API.Options) throws -> SavingType
    func save() throws -> SavingType
}

extension Saving {
    public func save() throws -> SavingType {
        return try save(options: [])
    }
}
