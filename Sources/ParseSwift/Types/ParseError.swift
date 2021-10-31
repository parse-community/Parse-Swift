//
//  ParseError.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/**
 An object with a Parse code and message.
 */
public struct ParseError: ParseType, Decodable, Swift.Error {
    /// The value representing the error from the Parse Server.
    public let code: Code
    /// The text representing the error from the Parse Server.
    public let message: String
    /// An error value representing a custom error from the Parse Server.
    public let otherCode: Int?

    enum CodingKeys: String, CodingKey {
        case code
        case message = "error"
    }

    /**
    `ParseError.Code` enum contains all custom error codes that are used
         as `code` for `Error` for callbacks on all classes.
    */
    public enum Code: Int, Swift.Error, Codable {

        /**
         Internal SDK Error. No information available
         */
        case unknownError = -1

        /**
         Internal server error. No information available.
         */
        case internalServer = 1

        /**
         The connection to the Parse servers failed.
         */
        case connectionFailed = 100

        /**
         Object doesn't exist, or has an incorrect password.
         */
        case objectNotFound = 101

        /**
         You tried to find values matching a datatype that doesn't
         support exact database matching, like an array or a dictionary.
         */
        case invalidQuery = 102

        /**
         Missing or invalid classname. Classnames are case-sensitive.
         They must start with a letter, and `a-zA-Z0-9_` are the only valid characters.
         */
        case invalidClassName = 103

        /**
         Missing object id.
         */
        case missingObjectId = 104

        /**
         Invalid key name. Keys are case-sensitive.
         They must start with a letter, and `a-zA-Z0-9_` are the only valid characters.
         */
        case invalidKeyName = 105

        /**
         Malformed pointer. Pointers must be arrays of a classname and an object id.
         */
        case invalidPointer = 106

        /**
         Malformed json object. A json dictionary is expected.
         */
        case invalidJSON = 107

        /**
         Tried to access a feature only available internally.
         */
        case commandUnavailable = 108

        /**
         Field set to incorrect type.
         */
        case incorrectType = 111

        /**
         Invalid channel name. A channel name is either an empty string (the broadcast channel)
         or contains only `a-zA-Z0-9_` characters and starts with a letter.
         */
        case invalidChannelName = 112

        /**
         Invalid device token.
         */
        case invalidDeviceToken = 114

        /**
         Push is misconfigured. See details to find out how.
         */
        case pushMisconfigured = 115

        /**
         The object is too large.
         */
        case objectTooLarge = 116

        /**
         That operation isn't allowed for clients.
         */
        case operationForbidden = 119

        /**
         The results were not found in the cache.
         */
        case cacheMiss = 120

        /**
         Keys in `NSDictionary` values may not include `$` or `.`.
         */
        case invalidNestedKey = 121

        /**
         Invalid file name.
         A file name can contain only `a-zA-Z0-9_.` characters and should be between 1 and 36 characters.
         */
        case invalidFileName = 122

        /**
         Invalid ACL. An ACL with an invalid format was saved. This should not happen if you use `ACL`.
         */
        case invalidACL = 123

        /**
         The request timed out on the server. Typically this indicates the request is too expensive.
         */
        case timeout = 124

        /**
         The email address was invalid.
         */
        case invalidEmailAddress = 125

        /**
         Missing content type.
         */
        case missingContentType = 126

        /**
         Missing content length.
         */
        case missingContentLength = 127

        /**
         Invalid content length.
         */
        case invalidContentLength = 128

        /**
         File was too large.
         */
        case fileTooLarge = 129

        /**
         Failure saving a file.
         */
        case fileSaveFailure = 130

        /**
         A unique field was given a value that is already taken.
         */
        case duplicateValue = 137

        /**
         Role's name is invalid.
         */
        case invalidRoleName = 139

        /**
         Exceeded an application quota. Upgrade to resolve.
         */
        case exceededQuota = 140

        /**
         Cloud Code script had an error.
         */
        case scriptFailed = 141

        /**
         Cloud Code validation failed.
         */
        case validationFailed = 142

        /**
         Fail to convert data to image.
         */
        case invalidImageData = 143

        /**
         Unsaved file failure.
         */
        case unsavedFileFailure = 151

        /**
         An invalid push time.
         */
        case invalidPushTime = 152

        /**
         Fail to delete file.
         */
        case fileDeleteFailure = 153

        /**
         Fail to delete an unnamed file.
         */
        case fileDeleteUnnamedFailure = 161

        /**
         Application has exceeded its request limit.
         */
        case requestLimitExceeded = 155

        /**
         The request was a duplicate and has been discarded
         due to idempotency rules.
         */
        case duplicateRequest = 159

        /**
         Invalid event name.
         */
        case invalidEventName = 160

        /**
         Invalid value.
         */
        case invalidValue = 162

        /**
         Username is missing or empty.
         */
        case usernameMissing = 200

        /**
         Password is missing or empty.
         */
        case userPasswordMissing = 201

        /**
         Username has already been taken.
         */
        case usernameTaken = 202

        /**
         Email has already been taken.
         */
        case userEmailTaken = 203

        /**
         The email is missing, and must be specified.
         */
        case userEmailMissing = 204

        /**
         A user with the specified email was not found.
         */
        case userWithEmailNotFound = 205

        /**
         The user cannot be altered by a client without the session.
         */
        case userCannotBeAlteredWithoutSession = 206

        /**
         Users can only be created through sign up.
         */
        case userCanOnlyBeCreatedThroughSignUp = 207

        /**
         An existing account already linked to another user.
         */
        case accountAlreadyLinked = 208

        /**
         The current session token is invalid.
         */
        case invalidSessionToken = 209

        /**
         Error enabling or verifying MFA.
         */
        case mfaError = 210

        /**
         A valid MFA token must be provided.
         */
        case mfaTokenRequired = 211

        /**
         Linked id missing from request.
         */
        case linkedIdMissing = 250

        /**
         Invalid linked session.
         */
        case invalidLinkedSession = 251

        /**
         Error code indicating that a service being linked (e.g. Facebook or
         Twitter) is unsupported.
         */
        case unsupportedService = 252

        /**
         Error code indicating an invalid operation occured on schema
         */
        case invalidSchemaOperation = 255

        /**
         Error code indicating that there were multiple errors. Aggregate errors
         have an "errors" property, which is an array of error objects with more
         detail about each error that occurred.
         */
        case aggregateError = 600

        /**
         Error code indicating the client was unable to read an input file.
         */
        case fileReadError = 601

        /**
         Error code indicating a real error code is unavailable because
         we had to use an XDomainRequest object to allow CORS requests in
         Internet Explorer, which strips the body from HTTP responses that have
         a non-2XX status code.
         */
        case xDomainRequest = 602

        /**
         Error code indicating any other custom error sent from the Parse Server.
         */
        case other
    }
}

// MARK: Encodable
extension ParseError {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
    }
}

// MARK: Convenience Implementations
extension ParseError {

    init(code: Code, message: String) {
        self.code = code
        self.message = message
        self.otherCode = nil
    }
}

// MARK: Decodable
extension ParseError {

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            code = try values.decode(Code.self, forKey: .code)
            otherCode = nil
        } catch {
            code = .other
            otherCode = try values.decode(Int.self, forKey: .code)
        }
        message = try values.decode(String.self, forKey: .message)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseError: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let otherCode = otherCode else {
            return "ParseError code=\(code.rawValue) error=\(message)"
        }
        return "ParseError code=\(code.rawValue) error=\(message) otherCode=\(otherCode)"
    }
}

// MARK: CustomStringConvertible
extension ParseError: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}

// MARK: LocalizedError
extension ParseError: LocalizedError {
    public var errorDescription: String? {
        debugDescription
    }
}

// MARK: Compare Errors
public extension Error {

    /**
     Returns the respective `ParseError` if the given `ParseError` code is equal to the error.
     
    **Example use case:**
    ````
    if let parseError = error.equalsTo(.objectNotFound)  {
        print(parseError.description)
    }
    ````
     - parameter errorCode: A `ParseError` code to compare to.
     
     - returns: Returns the `ParseError` with respect to the `Error`. If the error is not a `ParseError`, returns nil.
     */
    func equalsTo(_ errorCode: ParseError.Code) -> ParseError? {
        guard let error = self as? ParseError,
                error.code == errorCode else {
            return nil
        }
        return error
    }

    /**
     Validates if the given `ParseError` code is equal to the error.
     
    **Example use case:**
    ````
    if error.equalsTo(.objectNotFound)  {
        //Do stuff
    }
    ````
     - parameter errorCode: A `ParseError` code to compare to.
     
     - returns: A boolean indicating whether or not the `Error` is the `errorCode`.
     */
    func equalsTo(_ errorCode: ParseError.Code) -> Bool {
        guard equalsTo(errorCode) != nil else {
            return false
        }
        return true
    }

    /**
     Returns the respective `ParseError` if the `Error` is contained in the array of `ParseError` codes.
     
    **Example use case:**
    ````
    if let parseError = error.containedIn([.objectNotFound, .invalidQuery])  {
        print(parseError.description)
    }
    ````
     - parameter errorCodes: An array of zero or more of `ParseError` codes to compare to.
     
     - returns: Returns the `ParseError` with respect to the `Error`. If the error is not a `ParseError`, returns nil.
     */
    func containedIn(_ errorCodes: [ParseError.Code]) -> ParseError? {
        guard let error = self as? ParseError,
              errorCodes.contains(error.code) == true else {
            return nil
        }
        return error
    }

    /**
     Returns the respective `ParseError` if the `Error` is contained in the list of `ParseError` codes.
     
    **Example use case:**
    ````
    if let parseError = error.containedIn(.objectNotFound, .invalidQuery)  {
        print(parseError.description)
    }
    ````
     - parameter errorCodes: A variadic amount of zero or more of `ParseError` codes to compare to.
     
     - returns: Returns the `ParseError` with respect to the `Error`. If the error is not a `ParseError`, returns nil.
     */
    func containedIn(_ errorCodes: ParseError.Code...) -> ParseError? {
        containedIn(errorCodes)
    }

    /**
     Validates if the given `ParseError` codes contains the error.
     
    **Example use case:**
    ````
    if error.containedIn([.objectNotFound, .invalidQuery])  {
        //Do stuff
    }
    ````
     - parameter errorCodes: An array of zero or more of `ParseError` codes to compare to.
     
     - returns: A boolean indicating whether or not the `Error` is contained in the `errorCodes`.
     */
    func containedIn(_ errorCodes: [ParseError.Code]) -> Bool {
        guard containedIn(errorCodes) != nil else {
            return false
        }
        return true
    }

    /**
     Validates if the given `ParseError` codes contains the error.
     
    **Example use case:**
    ````
    if error.containedIn(.objectNotFound, .invalidQuery)  {
        //Do stuff
    }
    ````
     - parameter errorCodes: A variadic amount of zero or more of `ParseError` codes to compare to.
     
     - returns: A boolean indicating whether or not the `Error` is contained in the `errorCodes`.
     */
    func containedIn(_ errorCodes: ParseError.Code...) -> Bool {
        containedIn(errorCodes)
    }
}
