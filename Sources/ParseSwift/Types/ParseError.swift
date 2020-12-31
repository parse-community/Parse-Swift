//
//  ParseError.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public struct ParseError: ParseType, Decodable, Swift.Error {
    public let code: Code
    public let message: String

    public var localizedDescription: String {
        return "ParseError code=\(code.rawValue) error=\(message)"
    }

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
        case scriptError = 141
        /**
         Cloud Code validation failed.
         */
        case validationError = 142
        /**
         Product purchase receipt is missing.
         */
        case receiptMissing = 143
        /**
         Product purchase receipt is invalid.
         */
        case invalidPurchaseReceipt = 144
        /**
         Payment is disabled on this device.
         */
        case paymentDisabled = 145
        /**
         The product identifier is invalid.
         */
        case invalidProductIdentifier = 146
        /**
         The product is not found in the App Store.
         */
        case productNotFoundInAppStore = 147
        /**
         The Apple server response is not valid.
         */
        case invalidServerResponse = 148
        /**
         Product fails to download due to file system error.
         */
        case productDownloadFileSystemFailure = 149
        /**
         Fail to convert data to image.
         */
        case invalidImageData = 150
        /**
         Unsaved file.
         */
        case unsavedFile = 151
        /**
         Fail to delete file.
         */
        case fileDeleteFailure = 153
        /**
         Application has exceeded its request limit.
         */
        case requestLimitExceeded = 155
        /**
         Invalid event name.
         */
        case invalidEventName = 160
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
         Error code indicating that the current session token is invalid.
         */
        case invalidSessionToken = 209

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
    }
}

extension ParseError {

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(Code.self, forKey: .code)
        message = try values.decode(String.self, forKey: .message)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
    }
}
