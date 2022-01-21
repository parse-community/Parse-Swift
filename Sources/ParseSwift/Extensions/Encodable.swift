//
//  Encodable.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

internal extension Encodable {
    func isEqual(_ other: Encodable) -> Bool {
        guard let lhsData = try? ParseCoding.parseEncoder().encode(self),
              let lhsString = String(data: lhsData, encoding: .utf8),
              let rhsData = try? ParseCoding.parseEncoder().encode(other),
              let rhsString = String(data: rhsData, encoding: .utf8) else {
         return false
        }
        return lhsString == rhsString
    }
}
