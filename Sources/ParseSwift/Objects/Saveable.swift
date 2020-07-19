//
//  Saveable.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Saveable: Codable {
    associatedtype SavingType

    func save(options: API.Options) throws -> SavingType
    func save() throws -> SavingType
}

extension Saveable {
    public func save() throws -> SavingType {
        return try save(options: [])
    }
}
