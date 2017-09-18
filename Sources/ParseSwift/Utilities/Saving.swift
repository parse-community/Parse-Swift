//
//  Saving.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol Saving: Codable {
    associatedtype SavingType
    func save(options: API.Option, callback: @escaping ((SavingType?, Error?) -> Void)) -> Cancellable
    func save(callback: @escaping ((SavingType?, Error?) -> Void)) -> Cancellable
}

extension Saving {
    public func save(callback: @escaping ((SavingType?, Error?) -> Void)) -> Cancellable {
        return save(callback: callback)
    }
}
