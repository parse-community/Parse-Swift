//
//  ParseObjectType.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

// MARK: ParseCoding
internal enum ParseCoding {}

// MARK: Coders
extension ParseCoding {
    private static let forbiddenKeys = Set(["createdAt", "updatedAt", "objectId", "className"])

    static func jsonEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = jsonDateEncodingStrategy
        return encoder
    }

    static func jsonDecoder() -> JSONDecoder {
        let encoder = JSONDecoder()
        encoder.dateDecodingStrategy = jsonDateDecodingStrategy
        return encoder
    }

    static func parseEncoder() -> ParseEncoder {
        let encoder = ParseEncoder()
        encoder.dateEncodingStrategy = parseDateEncodingStrategy
        encoder.shouldEncodeKey = { (key, path) -> Bool in
            if path.count == 0 // top level
                && Self.forbiddenKeys.contains(key) {
                return false
            }
            return true
        }

        return encoder
    }
}

// MARK: Dates
extension ParseCoding {
    enum DateEncodingKeys: String, CodingKey {
        case iso
        case type = "__type"
    }

    static let dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }()

    static let jsonDateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom({ (date, enc) in
        var container = enc.container(keyedBy: DateEncodingKeys.self)
        try container.encode("Date", forKey: .type)
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .iso)
    })

    static let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
        var container = enc.container(keyedBy: DateEncodingKeys.self)
        try container.encode("Date", forKey: .type)
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .iso)
    })

    static let jsonDateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (dec) -> Date in
        do {
            let container = try dec.singleValueContainer()
            let decodedString = try container.decode(String.self)
            return dateFormatter.date(from: decodedString)!
        } catch let error {
            let container = try dec.container(keyedBy: DateEncodingKeys.self)
            if let decoded = try container.decodeIfPresent(String.self, forKey: .iso) {
                return dateFormatter.date(from: decoded)!
            }
        }

        throw ParseError(code: .unknownError, message: "unable to decode")
    })
}
