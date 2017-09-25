//
//  SecureStorage.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

protocol SecureStorage {
    init(service: String)
    func object(forKey: String) -> Any?
    func set(object: Any?, forKey: String) -> Bool

    subscript (key: String) -> Any? { get }
    func removeObject(forKey: String) -> Bool
    func removeAllObjects() -> Bool
}
