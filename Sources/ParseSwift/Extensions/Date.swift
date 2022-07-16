//
//  Date.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// MARK: Date
internal extension Date {
    var parseFormatted: String {
        ParseCoding.dateFormatter.string(from: self)
    }

    var parseRepresentation: [String: String] {
        ["__type": "Date", "iso": parseFormatted]
    }
}
