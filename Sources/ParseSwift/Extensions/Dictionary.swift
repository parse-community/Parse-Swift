//
//  Dictionary.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

internal extension Dictionary where Key == String, Value == String? {
    func getURLQueryItems() -> [URLQueryItem] {
        sorted { $0.key < $1.key }.map { (key, value) -> URLQueryItem in
            URLQueryItem(name: key, value: value)
        }
    }
}
