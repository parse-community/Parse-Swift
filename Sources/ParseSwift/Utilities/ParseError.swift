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

extension ParseError {
    static func unknownResult() -> NSError {
        return NSError(domain: "Neither data nor error was set.", code: -1, userInfo: nil)
    }
}
