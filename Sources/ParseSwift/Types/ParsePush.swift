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
public struct ParsePush<V: ParsePushPayloadable>: ParseTypeable {
    /**
     The query that determines what installations should receive the notification.
     - warning: Cannot send a notification with this valuel and `channels` both set.
     */
    public var `where`: QueryWhere?
    /**
     An Array of channels to push to.
     - warning: Cannot send a notification with this valuel and `where` both set.
     */
    public var channels: Set<String>?
    /// The payload to send.
    public var payload: V?
    /// When to send the notification.
    public var pushTime: Date?
    /**
     The UNIX timestamp when the notification should expire.
     If the notification cannot be delivered to the device, will retry until it expires.
     An expiry of **0** indicates that the notification expires immediately, therefore
     no retries will be attempted.
     - note: This should not be set directly using a **Date** type. Instead it should
     be set using `expirationDate`.
     - warning: Cannot send a notification with this valuel and `expirationInterval` both set.
     */
    var expirationTime: TimeInterval?

    /**
     The date when the notification should expire.
     If the notification cannot be delivered to the device, will retry until it expires.
     - note: This takes any date and turns it into a UNIX timestamp and sets the
     value of `expirationTime`.
     - warning: Cannot send a notification with this valuel and `expirationInterval` both set.
     */
    var expirationDate: Date? {
        get {
            guard let interval = expirationTime else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            expirationTime = newValue?.timeIntervalSince1970
        }
    }
    /**
     The seconds from now to expire the notification.
     - warning: Cannot send a notification with this valuel and `expirationTime` both set.
     */
    public var expirationInterval: Int?

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
     - parameter expirationDate: The date to expire the notification. Defaults to **nil**.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init(payload: V,
                pushTime: Date? = nil,
                expirationDate: Date? = nil) {
        self.payload = payload
        self.pushTime = pushTime
        self.expirationDate = expirationDate
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
     - parameter expirationDate: The date to expire the notification. Defaults to **nil**.
     - requires: `.useMasterKey` has to be available. It is recommended to only
     use the master key in server-side applications where the key is kept secure and not
     exposed to the public.
     - warning: `expirationTime` and `expirationInterval` cannot be set at the same time.
    */
    public init<U>(payload: V,
                   query: Query<U>,
                   pushTime: Date? = nil,
                   expirationDate: Date? = nil) where U: ParseInstallation {
        self.payload = payload
        self.`where` = query.`where`
        self.pushTime = pushTime
        self.expirationDate = expirationDate
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
    public init<U>(payload: V,
                   query: Query<U>,
                   pushTime: Date? = nil,
                   expirationInterval: Int?) where U: ParseInstallation {
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

    func sendCommand() -> API.NonParseBodyCommand<Self, String> {

        return API.NonParseBodyCommand(method: .POST,
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
                     completion: @escaping (Result<ParsePushStatus<V>, ParseError>) -> Void) {
        var options = options
        options.insert(.useMasterKey)
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let query = ParsePushStatus<V>.query("objectId" == statusId)
        query.first(options: options, completion: completion)
    }
}
