//
//  AddUnique.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal struct AddUnique<T>: Encodable where T: Encodable {
    let __op: String = "AddUnique" // swiftlint:disable:this identifier_name
    let objects: [T]
}
