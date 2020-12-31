//
//  ParseCoding.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

// MARK: ParseCoding
public enum ParseCoding {}

// MARK: Coders
extension ParseCoding {

    ///This should only be used for Unit tests, don't use in SDK
    static func jsonEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = jsonDateEncodingStrategy
        return encoder
    }

    static func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return decoder
    }

    static func parseEncoder(skipKeys: Bool = true) -> ParseEncoder {
        ParseEncoder(
            dateEncodingStrategy: parseDateEncodingStrategy
        )
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

    static let jsonDateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom(parseDateEncodingStrategy)

    static let parseDateEncodingStrategy: AnyCodable.DateEncodingStrategy = { (date, encoder) in
        var container = encoder.container(keyedBy: DateEncodingKeys.self)
        try container.encode("Date", forKey: .type)
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .iso)
    }

    static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (decoder) -> Date in
        do {
            let container = try decoder.singleValueContainer()
            let decodedString = try container.decode(String.self)

            if let date = dateFormatter.date(from: decodedString) {
                return date
            } else {
                throw ParseError(
                    code: .unknownError,
                    message: "An invalid date string was provided when decoding dates."
                )
            }
        } catch let error {
            let container = try decoder.container(keyedBy: DateEncodingKeys.self)

            if
                let decoded = try container.decodeIfPresent(String.self, forKey: .iso),
                let date = dateFormatter.date(from: decoded)
            {
                return date
            } else {
                throw ParseError(
                    code: .unknownError,
                    message: "An invalid date string was provided when decoding dates."
                )
            }
        }
    })
}
