//
//  Date Formatting.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

enum DateEncodingKeys: String, CodingKey {
    case iso
    case type = "__type"
}

let dateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    return dateFormatter
}()

let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .type)
    let dateString = dateFormatter.string(from: date)
    try container.encode(dateString, forKey: .iso)
})

let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom({ (date, enc) in
    var container = enc.container(keyedBy: DateEncodingKeys.self)
    try container.encode("Date", forKey: .type)
    let dateString = dateFormatter.string(from: date)
    try container.encode(dateString, forKey: .iso)
})

internal extension Date {
    internal func parseFormatted() -> String {
        return dateFormatter.string(from: self)
    }
    internal var parseRepresentation: [String: String] {
        return ["__type": "Date", "iso": parseFormatted()]
    }
}

let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (dec) -> Date in
    do {
        let container = try dec.singleValueContainer()
        let decodedString = try container.decode(String.self)
        return dateFormatter.date(from: decodedString)!
    } catch let e {
        let container = try dec.container(keyedBy: DateEncodingKeys.self)
        if let decoded = try container.decodeIfPresent(String.self, forKey: .iso) {
            return dateFormatter.date(from: decoded)!
        }
    }
    throw NSError(domain: "", code: -1, userInfo: nil)
})
