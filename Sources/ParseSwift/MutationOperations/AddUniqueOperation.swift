//
//  AddUniqueOperation.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal struct AddUniqueOperation<T>: Encodable where T: Encodable {
    let __op: String = "AddUnique"
    let objects: [T]
}
