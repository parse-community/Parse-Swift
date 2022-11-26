//
//  ParseHookResponseSuccess.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Build a response after processing a `ParseHookFunctionRequest`
 or `ParseHookTriggerRequest`.
 */
public struct ParseHookResponse<R: Codable & Equatable>: ParseTypeable {
    /// The data to return in the response.
    public var success: R?
    /// An object with a Parse code and message.
    public var error: ParseError?

    enum CodingKeys: String, CodingKey {
        case success, error
    }
}

// MARK: Default Implementation
public extension ParseHookResponse {
    /**
     Create a successful response after processing a `ParseHookFunctionRequest`
     or `ParseHookTriggerRequest`.
     - parameter success: The data to return in the response.
     */
    init(success: R) {
        self.success = success
    }

    /**
     Create an error reponse to a `ParseHookFunctionRequest` or
     `ParseHookTriggerRequest`  with a `ParseError`.
     - parameter error: The `ParseError`.
     */
    init(error: ParseError) {
        self.error = error
    }
}

// MARK: Encodable
public extension ParseHookResponse {
    func encode(to encoder: Encoder) throws {
        guard let success = success else {
            var container = encoder.singleValueContainer()
            try container.encode(error)
            return
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
    }
}

// MARK: Decodable
public extension ParseHookResponse {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self.success = try values.decode(R.self, forKey: .success)
        } catch {
            let errorValue = try decoder.singleValueContainer()
            self.error = try errorValue.decode(ParseError.self)
        }
    }
}

// MARK: LocalizedError
extension ParseHookResponse: LocalizedError {
    public var errorDescription: String? {
        debugDescription
    }
}
