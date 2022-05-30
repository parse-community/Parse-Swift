//
//  IncrementOperation.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal struct Increment: Encodable {
    let __op: Operation = .increment // swiftlint:disable:this identifier_name
    let amount: Int
}
