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
/*
    /// The text representing the error from the Parse Server.
    public var message: String?
    /// The value representing the error from the Parse Server.
    public var code: ParseError.Code?
    /// An error value representing a custom error from the Parse Server.
    public var otherCode: Int? */
    // var error: String?

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
        /* self.message = error.message
        self.otherCode = error.otherCode */
    }
/*
    /**
     Create an error with a known code and custom message.
     - parameter code: The known Parse code.
     - parameter message: The custom message.
     */
    init(code: ParseError.Code, message: String) {
        self.code = code
        self.message = message
    }

    /**
     Create an error with a custom code and custom message.
     - parameter otherCode: The custom code.
     - parameter message: The custom message.
     */
    init(otherCode: Int, message: String) {
        self.code = .other
        self.message = message
        self.otherCode = otherCode
    }

    /**
     Convert to `ParseError`.
     - parameter otherCode: The custom code.
     - returns: A `ParseError`.
     - throws: An error of type `ParseError`.
     */
     func convertToParseError() throws -> ParseError {
        guard let code = code,
              let message = message else {
            throw ParseError(code: .unknownError,
                             message: "Unable to convert to error; missing valid fields")
        }
        return ParseError(code: code,
                          message: message,
                          otherCode: otherCode,
                          error: error)
    } */
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
