//
//  ParseClassLevelPermisioinable.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/27/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseClassLevelPermisioinable: Codable, Equatable {
    var protectedFields: [String: Set<String>]? { get set }
    var readUserFields: Set<String>? { get set }
    var writeUserFields: Set<String>? { get set }
}
