//
//  Extensions.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

import Foundation

// MARK: Date
internal extension Date {
    func parseFormatted() -> String {
        return ParseCoding.dateFormatter.string(from: self)
    }

    var parseRepresentation: [String: String] {
        return ["__type": "Date", "iso": parseFormatted()]
    }
}

// MARK: JSONEncoder
extension JSONEncoder {
    func encodeAsString<T>(_ value: T) throws -> String where T: Encodable {
        guard let string = String(data: try encode(value), encoding: .utf8) else {
            throw ParseError(code: .unknownError, message: "Unable to encode object...")
        }

        return string
    }
}

// MARK: ParseObject
public extension ParseObject {
    func getEncoder(skipKeys: Bool = true) -> ParseEncoder {
        return ParseCoding.parseEncoder(skipKeys: skipKeys)
    }

    func getJSONEncoder() -> JSONEncoder {
        return ParseCoding.jsonEncoder()
    }

    func getDecoder() -> JSONDecoder {
        ParseCoding.jsonDecoder()
    }
}
