//
//  ParseCoding.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

// MARK: ParseCoding
/// Custom coding for Parse objects.
enum ParseCoding {}

// MARK: Coders
extension ParseCoding {

    /// The JSON Encoder setup with the correct `dateEncodingStrategy`
    /// strategy for `Parse`.
    static func jsonEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = parseDateEncodingStrategy
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    /// The JSON Decoder setup with the correct `dateDecodingStrategy`
    /// strategy for `Parse`. This encoder is used to decode all data received
    /// from the server.
    static func jsonDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return decoder
    }

    /// The Parse Encoder is used to JSON encode all `ParseObject`s and
    /// types in a way meaninful for a Parse Server to consume.
    static func parseEncoder() -> ParseEncoder {
        ParseEncoder(
            dateEncodingStrategy: parseDateEncodingStrategy,
            outputFormatting: .sortedKeys
        )
    }
}

// MARK: Coding
public extension ParseObject {

    /// The Parse encoder is used to JSON encode all `ParseObject`s and
    /// types in a way meaninful for a Parse Server to consume.
    static func getEncoder() -> ParseEncoder {
        return ParseCoding.parseEncoder()
    }

    /// The Parse encoder is used to JSON encode all `ParseObject`s and
    /// types in a way meaninful for a Parse Server to consume.
    func getEncoder() -> ParseEncoder {
        return Self.getEncoder()
    }

    /// The JSON encoder setup with the correct `dateEncodingStrategy`
    /// strategy to send data to a Parse Server.
    static func getJSONEncoder() -> JSONEncoder {
        return ParseCoding.jsonEncoder()
    }

    /// The JSON encoder setup with the correct `dateEncodingStrategy`
    /// strategy to send data to a Parse Server.
    func getJSONEncoder() -> JSONEncoder {
        return Self.getJSONEncoder()
    }

    /// The JSON decoder setup with the correct `dateDecodingStrategy`
    /// strategy to decode data from a Parse Server. This encoder is used to decode all data received
    /// from the server.
    static func getDecoder() -> JSONDecoder {
        ParseCoding.jsonDecoder()
    }

    /// The JSON decoder setup with the correct `dateDecodingStrategy`
    /// strategy to decode data from a Parse Server. This encoder is used to decode all data received
    /// from the server.
    func getDecoder() -> JSONDecoder {
        Self.getDecoder()
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
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }()

    static let parseDateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .custom { (date, encoder) in
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
        } catch {
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
