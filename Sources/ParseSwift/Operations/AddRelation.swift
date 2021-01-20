//
//  AddRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

internal struct AddRelation<T>: Encodable where T: ParseObject {
    let __op: String = "AddRelation" // swiftlint:disable:this identifier_name
    let objects: [Pointer<T>]

    init(objects: [T]) {
        self.objects = objects.compactMap { $0.toPointer() }
    }
}
