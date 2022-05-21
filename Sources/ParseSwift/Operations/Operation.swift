//
//  Operation.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

enum Operation: String, Codable {
    case add = "Add"
    case addRelation = "AddRelation"
    case addUnique = "AddUnique"
    case delete = "Delete"
    case increment = "Increment"
    case remove = "Remove"
    case removeRelation = "RemoveRelation"
}
