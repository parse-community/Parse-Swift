//
//  ParseObjectType.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal extension ParseObject {
    func getEncoder() -> ParseEncoder {
        return getParseEncoder()
    }
}

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
    func parseFormatted() -> String {
        return dateFormatter.string(from: self)
    }
    var parseRepresentation: [String: String] {
        return ["__type": "Date", "iso": parseFormatted()]
    }
}

let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom({ (dec) -> Date in
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

func getJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = dateEncodingStrategy
    return encoder
}

private let forbiddenKeys = ["createdAt", "updatedAt", "objectId", "className"]

func getParseEncoder() -> ParseEncoder {
    let encoder = ParseEncoder()
    encoder.dateEncodingStrategy = parseDateEncodingStrategy
    encoder.shouldEncodeKey = { (key, path) -> Bool in
        if path.count == 0 // top level
            && forbiddenKeys.firstIndex(of: key) != nil {
            return false
        }
        return true
    }
    return encoder
}

extension JSONEncoder {
    func encodeAsString<T>(_ value: T) throws -> String where T: Encodable {
        guard let string = String(data: try encode(value), encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Unable to encode object...")
        }
        return string
    }
}

func getDecoder() -> JSONDecoder {
    let encoder = JSONDecoder()
    encoder.dateDecodingStrategy = dateDecodingStrategy
    return encoder
}
