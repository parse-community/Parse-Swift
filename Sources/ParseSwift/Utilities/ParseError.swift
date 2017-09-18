//
//  ParseError.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public struct ParseError: Error, Decodable {
    let code: Int
    let error: String
}
