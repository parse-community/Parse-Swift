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

// MARK: Coding
public extension ParseObject {
    /// The Parse encoder is used to JSON encode all `ParseObject`s and
    /// types in a way meaninful for a Parse Server to consume.
    func getEncoder() -> ParseEncoder {
        return ParseCoding.parseEncoder()
    }

    /// The JSON encoder setup with the correct `dateEncodingStrategy`
    /// strategy to send data to a Parse Server.
    func getJSONEncoder() -> JSONEncoder {
        return ParseCoding.jsonEncoder()
    }

    /// The JSON decoder setup with the correct `dateDecodingStrategy`
    /// strategy to decode data from a Parse Server. This encoder is used to decode all data received
    /// from the server.
    func getDecoder() -> JSONDecoder {
        ParseCoding.jsonDecoder()
    }
}
