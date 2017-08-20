//
//  IncrementOperation.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal struct IncrementOperation: Encodable {
    let __op: String = "Increment"
    let amount: Int
}
