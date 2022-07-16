//
//  Add.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal struct Add<T>: Encodable where T: Encodable {
    let __op: Operation = .add // swiftlint:disable:this identifier_name
    let objects: [T]
}
