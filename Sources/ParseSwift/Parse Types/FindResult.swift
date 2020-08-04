//
//  FindResult.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

internal struct FindResult<T>: Codable where T: ParseObject {
    let results: [T]
    let count: Int?
}
