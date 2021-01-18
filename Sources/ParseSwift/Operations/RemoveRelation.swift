//
//  RemoveRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

internal struct RemoveRelation<T>: Encodable where T: Encodable {
    let __op: String = "RemoveRelation" // swiftlint:disable:this identifier_name
    let objects: [T]
}
