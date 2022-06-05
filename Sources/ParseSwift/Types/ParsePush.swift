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
public struct ParsePush<U: ParseInstallation, V: ParsePushPayloadDatable>: ParseType, Decodable {
    /// The query that determines what installations should receive the notification.
    public var `where`: Query<U>?
    /// An Array of channels to push to.
    public var channels: Set<String>?
    /// The payload to send.
    public var data: V?
    /// When to send the notification.
    public var pushTime: Date?
    /// When to expire the notification.
    public var expirationTime: Date?
    /// The seconds from now to expire the notification.
    public var expirationInterval: Int?

    enum CodingKeys: String, CodingKey {
        case pushTime = "push_time"
        case expirationTime = "expiration_time"
        case expirationInterval = "expiration_interval"
        case `where`, channels, data
    }

    /**
     Create an instance of  `ParsePush` with a given expiration date.
     - parameter query: The query that determines what installations should receive the notification.
     - parameter pushTime: When to send the notification.
     - parameter expirationTime: The date to expire the notification.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(query: Query<U>, pushTime: Date?, expirationTime: Date?) {
        self.`where` = query
        self.pushTime = pushTime
        self.expirationTime = expirationTime
    }

    /**
     Create an instance of  `ParsePush` that expires after a given amount of seconds.
     - parameter query: The query that determines what installations should receive the notification.
     - parameter pushTime: When to send the notification.
     - parameter expirationInterval: How many seconds to expire the notification after now.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(query: Query<U>, pushTime: Date?, expirationInterval: Int?) {
        self.`where` = query
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
        if expirationTime != nil && expirationInterval != nil {
            let error =  ParseError(code: .unknownError,
                                    message: "expirationTime and expirationInterval cannot both be set.")
            completion(.failure(error))
            return
        }
        if `where` != nil && channels != nil {
            let error =  ParseError(code: .unknownError,
                                    message: "query and channels cannot both be set.")
            completion(.failure(error))
            return
        }
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
            try ParseCoding.jsonDecoder().decode(String .self, from: data)
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
