//
//  RemoveRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

internal struct RemoveRelation<T>: Encodable where T: ParseObject {
    let __op: String = "RemoveRelation" // swiftlint:disable:this identifier_name
    let objects: [Pointer<T>]

    init(objects: [T]) throws {
        self.objects = try objects.compactMap { try $0.toPointer() }
    }
}
