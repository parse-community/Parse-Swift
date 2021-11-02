//
//  Overloads.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public func == <W>(_ lhs: W, rhs: W) -> Bool where W: Encodable {
    guard let lhsData = try? ParseCoding.parseEncoder().encode(lhs),
          let lhsString = String(data: lhsData, encoding: .utf8),
          let rhsData = try? ParseCoding.parseEncoder().encode(rhs),
          let rhsString = String(data: rhsData, encoding: .utf8) else {
        return false
    }
    return lhsString == rhsString
}

public func != <W>(_ lhs: W, rhs: W) -> Bool where W: Encodable {
    guard let lhsData = try? ParseCoding.parseEncoder().encode(lhs),
          let lhsString = String(data: lhsData, encoding: .utf8),
          let rhsData = try? ParseCoding.parseEncoder().encode(rhs),
          let rhsString = String(data: rhsData, encoding: .utf8) else {
        return false
    }
    return lhsString != rhsString
}
