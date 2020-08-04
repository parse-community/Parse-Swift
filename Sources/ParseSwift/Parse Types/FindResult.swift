//
//  FindResult.swift
//  ParseSwift
//
//  Created by Pranjal Satija on 8/4/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

internal struct FindResult<T>: Codable where T: ParseObject {
    let results: [T]
    let count: Int?
}
