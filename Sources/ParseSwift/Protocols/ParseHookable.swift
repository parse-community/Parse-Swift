//
//  ParseHookable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/15/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Hooks and Triggers should conform to `ParseHookable`.
 */
public protocol ParseHookable: ParseTypeable {
    /// Create an empty initializer.
    init()
}
