//
//  ParseHookable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/15/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseHookable: ParseType, Decodable, Equatable {
    init()
}
