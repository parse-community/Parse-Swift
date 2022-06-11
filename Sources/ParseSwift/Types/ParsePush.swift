//
//  ParsePush.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/4/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 Send and check the status of push notificaitons.
 - requires: `.useMasterKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParsePush<U: ParseInstallation, V: ParsePushPayloadable>: ParseType, Decodable {
    /**
     The query that determines what installations should receive the notification.
     - warning: Setting this value will unset `channels` as they both cannot be
     set at the same time.
     */
    public var `where`: QueryWhere? {
        willSet {
            channels = nil
        }
    }
    /**
     An Array of channels to push to.
     - warning: Setting this value will unset `where` as they both cannot be
     set at the same time.
     */
    public var channels: Set<String>? {
        willSet {
            `where` = nil
        }
    }
    /// The payload to send.
    public var payload: V?
    /// When to send the notification.
    public var pushTime: Date?
    /**
     When to expire the notification.
     - warning: Setting this value will unset `expirationInterval` as they both cannot be
     set at the same time.
     */
    public var expirationTime: Date? {
        willSet {
            expirationInterval = nil
        }
    }
    /**
     The seconds from now to expire the notification.
     - warning: Setting this value will unset `expirationTime` as they both cannot be
     set at the same time.
     */
    public var expirationInterval: Int? {
        willSet {
            expirationTime = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case pushTime = "push_time"
        case expirationTime = "expiration_time"
        case expirationInterval = "expiration_interval"
        case payload = "data"
        case `where`, channels
    }

    /**
     Create an instance of  `ParsePush` with a given expiration date.
     - parameter payload: The payload information to send.
     - parameter pushTime: When to send the notification.  Defaults to **nil**.
     - parameter expirationTime: The date to expire the notification. Defaults to **nil**.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(payload: V,
                pushTime: Date? = nil,
                expirationTime: Date? = nil) {
        self.payload = payload
        self.pushTime = pushTime
        self.expirationTime = expirationTime
    }

    /**
     Create an instance of  `ParsePush` that expires after a given amount of seconds.
     - parameter payload: The payload information to send.
     - parameter pushTime: When to send the notification.  Defaults to **nil**.
     - parameter expirationInterval: How many seconds to expire the notification after now.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(payload: V,
                pushTime: Date? = nil,
                expirationInterval: Int?) {
        self.payload = payload
        self.pushTime = pushTime
        self.expirationInterval = expirationInterval
    }

    /**
     Create an instance of  `ParsePush` with a given expiration date.
     - parameter payload: The payload information to send.
     - parameter query: The query that determines what installations should receive the notification.
     Defaults to **nil**.
     - parameter pushTime: When to send the notification.  Defaults to **nil**.
     - parameter expirationTime: The date to expire the notification. Defaults to **nil**.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(payload: V,
                query: Query<U>,
                pushTime: Date? = nil,
                expirationTime: Date? = nil) {
        self.payload = payload
        self.`where` = query.`where`
        self.pushTime = pushTime
        self.expirationTime = expirationTime
    }

    /**
     Create an instance of  `ParsePush` that expires after a given amount of seconds.
     - parameter payload: The payload information to send.
     - parameter query: The query that determines what installations should receive the notification.
     Defaults to **nil**.
     - parameter pushTime: When to send the notification.  Defaults to **nil**.
     - parameter expirationInterval: How many seconds to expire the notification after now.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(payload: V,
                query: Query<U>,
                pushTime: Date? = nil,
                expirationInterval: Int?) {
        self.payload = payload
        self.`where` = query.`where`
        self.pushTime = pushTime
        self.expirationInterval = expirationInterval
    }
}

// MARK: Sendable
extension ParsePush {

    /**
     Sends the  `ParsePush` *asynchronously* from the server and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: expirationTime and expirationInterval cannot be set at the same time.
    */
    public func send(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<String, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        sendCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue,
                          completion: completion)
    }

    func sendCommand() -> API.Command<Self, String> {

        return API.Command(method: .POST,
                           path: .push,
                           body: self) { (data) -> String in
            guard let response = try? ParseCoding.jsonDecoder().decode(PushResponse.self, from: data) else {
                throw ParseError(code: .unknownError,
                                 message: "The server is missing \"X-Parse-Push-Status-Id\" in its header response")
            }
            guard let success = try? ParseCoding.jsonDecoder().decode(BooleanResponse.self,
                                                                      from: response.data).result else {
                throw ParseError(code: .unknownError, message: "The server did not resturn a Boolean response")
            }
            if success {
                return response.statusId
            } else {
                throw ParseError(code: .unknownError, message: "Push was unsuccessful")
            }
        }
    }
}

// MARK: Fetchable
public extension ParsePush {
    /**
     Fetches the  `ParsePushStatus` by `objectId` *asynchronously* from the server and
     executes the given callback block.
     - parameter statusId: The `objectId` of the `ParsePushStatus`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func fetchStatus(_ statusId: String,
                     options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<ParsePushStatus<U, V>, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let query = ParsePushStatus<U, V>.query("objectId" == statusId)
        query.first(options: options, completion: completion)
    }
}

// MARK: CustomDebugStringConvertible
extension ParsePush: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "ParsePush ()"
        }
        return "ParsePush (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension ParsePush: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}
