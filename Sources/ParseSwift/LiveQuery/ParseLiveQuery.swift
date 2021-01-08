//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 The `ParseLiveQuery` class enables two-way communication to a Parse Live Query
 Server.
 
 In most cases, you will only need to create a singleton of `ParseLiveQuery`. Initializing
 new instances will create a new task/connection to the `ParseLiveQuery` server. When
 an instance is deinitialized it will automatically close it's connection gracefully.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class ParseLiveQuery: NSObject {
    //Task
    var task: URLSessionWebSocketTask!
    var url: URL!
    var isDisconnectedByUser = false {
        willSet {
            if newValue == true {
                isConnected = false
            }
        }
    }
    public weak var authenticationDelegate: ParseLiveQueryDelegate? {
        willSet {
            if newValue != nil {
                URLSession.liveQuery.authenticationDelegate = self
            } else {
                if let delegate = URLSession.liveQuery.authenticationDelegate as? ParseLiveQuery {
                    if delegate == self {
                        URLSession.liveQuery.authenticationDelegate = nil
                    }
                }
            }
        }
    }
    public weak var receiveDelegate: ParseLiveQueryDelegate?
    public internal(set) var isSocketEstablished = false { //URLSession has an established socket
        willSet {
            if newValue == false {
                isConnected = newValue
            }
        }
    }
    public internal(set) var isConnected = false {
        willSet {
            isConnecting = false
            if newValue == true {
                if let task = task {
                    //Resubscribe to all subscriptions

                    //Send all pending messages
                    self.pendingQueue.forEach {
                        let messageToSend = $0
                        URLSession.liveQuery.send(messageToSend.1.messageData, task: task) { _ in }
                    }
                }
            }
        }
    }
    public internal(set) var isConnecting = false

    //Subscription
    let requestIdGenerator: () -> RequestId
    var subscriptions = [RequestId: SubscriptionRecord]()
    var pendingQueue = [(RequestId, SubscriptionRecord)]() // Behave as FIFO to maintain sending order

    /**
     - parameter serverURL: The URL of the Parse Live Query Server to connect to.
     Defaults to `nil` in which case, it will use the URL passed in
     `ParseSwift.initialize(...liveQueryServerURL: URL)`. If no URL was passed,
     this assumes the current Parse Server URL is also the LiveQuery server.
     */
    public init?(serverURL: URL? = nil, isDefault: Bool = false) {

        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }
        super.init()

        if let userSuppliedURL = serverURL {
            url = userSuppliedURL
        } else if let liveQueryConfigURL = ParseConfiguration.liveQuerysServerURL {
            url = liveQueryConfigURL
        } else if let parseServerConfigURL = ParseConfiguration.serverURL {
            url = parseServerConfigURL
        } else {
            return nil
        }

        guard var components = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        url = components.url
        createTask()
        if isDefault {
            Self.setDefault(self)
        }
    }

    /// Gracefully disconnects from the ParseLiveQuery Server.
    deinit {
        if let task = self.task {
            try? close()
            authenticationDelegate = nil
            receiveDelegate = nil
            URLSession.liveQuery.delegates.removeValue(forKey: task)
        }
    }
}

// MARK: Helpers
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    static var client = ParseLiveQuery()

    func createTask() {
        if task == nil {
            task = URLSession.liveQuery.createTask(url)
        }
        task.resume()
        URLSession.liveQuery.receive(task)
        URLSession.liveQuery.delegates[task] = self
    }

    func removePendingSubscription(_ requestId: Int) {
        let requestIdToRemove = RequestId(value: requestId)
        pendingQueue.removeAll(where: { $0.0.value == requestId })
        //Remove in subscriptions just in case the server
        //responded before this was called
        subscriptions.removeValue(forKey: requestIdToRemove)
    }

    /// Set a specific ParseLiveQuery client to be the default for all `ParseLiveQuery` connections.
    /// - parameter client: The client to set as the default.
    class public func setDefault(_ client: ParseLiveQuery) {
        ParseLiveQuery.client = nil
        ParseLiveQuery.client = client
    }

    /// Get the default `ParseLiveQuery` client for all LiveQuery connections.
    class public func getDefault() -> ParseLiveQuery? {
        ParseLiveQuery.client
    }

    /// Check if a query has an active subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to verify.
    public func isSubscribed<T: ParseObject>(_ query: Query<T>) throws -> Bool {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        return subscriptions.contains(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }

    /// Check if a query has a pending subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to verify.
    public func isPendingSubscription<T: ParseObject>(_ query: Query<T>) throws -> Bool {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        return pendingQueue.contains(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }

    /// Remove a pending subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to remove.
    public func removePendingSubscription<T: ParseObject>(_ query: Query<T>) throws {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        pendingQueue.removeAll(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }
}

// MARK: Delegate
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func status(_ status: LiveQuerySocket.Status) {
        switch status {

        case .open:
            isSocketEstablished = true
            try? open(isUserWantsToConnect: false) { _ in }
        case .closed:
            isSocketEstablished = false
            if !isDisconnectedByUser {
                //Try to reconnect
                self.createTask()
            }
        }
    }

    func received(_ data: Data) {

        if let redirect = try? ParseCoding.jsonDecoder().decode(RedirectResponse.self, from: data) {
            if redirect.op == .redirect {
                url = redirect.url
                if isConnected {
                    try? self.close(false)
                    //Try to reconnect
                    self.createTask()
                }
            }
            return
        }

        if !self.isConnected {
            //Check if this is a connected response
            guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                  response.op == .connected else {
                //If not connected, shouldn't be receiving anything other than connection response
                guard let outOfOrderMessage = try? ParseCoding
                        .jsonDecoder()
                        .decode(NoBody.self, from: data) else {
                    let error = ParseError(code: .unknownError,
                                           // swiftlint:disable:next line_length
                                           message: "ParseLiveQuery Error: Received message out of order, but couldn't decode it")
                    receiveDelegate?.received(error)
                    return
                }
                let error = ParseError(code: .unknownError,
                                       // swiftlint:disable:next line_length
                                       message: "ParseLiveQuery Error: Received message out of order: \(outOfOrderMessage)")
                receiveDelegate?.received(error)
                return
            }
            self.isConnected = true
        } else {

            //Check if this is a error response
            if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
                if !error.reconnect {
                    //Treat this as a user disconnect because the server doesn't want to hear from us anymore
                    try? self.close()
                }
                guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                    //Turn LiveQuery error into ParseError
                    let parseError = ParseError(code: .unknownError,
                                                message: "LiveQuery error code: \(error.code) message: \(error.error)")
                    receiveDelegate?.received(parseError)
                    return
                }
                receiveDelegate?.received(parseError)
                return
            } else if let preliminaryMessage = try? ParseCoding.jsonDecoder()
                        .decode(PreliminaryMessageResponse.self,
                                from: data) {

                switch preliminaryMessage.op {
                case .subscribed:

                    if let subscribed = pendingQueue
                        .first(where: { $0.0.value == preliminaryMessage.requestId }) {
                        let requestId = RequestId(value: preliminaryMessage.requestId)
                        let isNew: Bool!
                        if subscriptions[requestId] != nil {
                            isNew = false
                            /*pendingQueue.removeAll(where: { $0.0.value == preliminaryMessage.requestId })
                            subscriptions[subscribed.0] = subscribed.1
                            subscribed.1.subscribeHandlerClosure?(false)*/
                        } else {
                            isNew = true
                        }
                        removePendingSubscription(subscribed.0.value)
                        subscriptions[subscribed.0] = subscribed.1
                        subscribed.1.subscribeHandlerClosure?(isNew)
                    }
                case .unsubscribed:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = subscriptions[requestId] else {
                        return
                    }
                    subscription.unsubscribeHandlerClosure?()
                    removePendingSubscription(preliminaryMessage.requestId)
                case .create, .update, .delete, .enter, .leave:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = subscriptions[requestId] else {
                        return
                    }
                    subscription.eventHandlerClosure?(data)
                default:
                    let error = ParseError(code: .unknownError,
                                           message: "ParseLiveQuery Error: Hit an undefined state.")
                    receiveDelegate?.received(error)
                }

            } else {
                let error = ParseError(code: .unknownError, message: "ParseLiveQuery Error: Hit an undefined state.")
                receiveDelegate?.received(error)
            }
        }
    }

    func receivedError(_ error: ParseError) {
        receiveDelegate?.received(error)
    }

    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?) {
        receiveDelegate?.receivedUnsupported(data, socketMessage: socketMessage)
    }

    func received(challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                URLCredential?) -> Void) {
        if let delegate = authenticationDelegate {
            delegate.received(challenge, completionHandler: completionHandler)
        } else if let parseAuthentication = ParseConfiguration.sessionDelegate.authentication {
            parseAuthentication(challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    #if !os(watchOS)
    func received(_ metrics: URLSessionTaskTransactionMetrics) {
        receiveDelegate?.received(metrics)
    }
    #endif
}

// MARK: Connection
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    ///Manually establish a connection to the `ParseLiveQuery` server.
    /// - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to `true`.
    /// - parameter completion: Returns `nil` if successful, an `Error` otherwise.
    public func open(isUserWantsToConnect: Bool = true, completion: @escaping (Error?) -> Void) throws {
        if isUserWantsToConnect {
            isDisconnectedByUser = false
        }
        if isConnected || isDisconnectedByUser {
            completion(nil)
            return
        }
        if isConnecting {
            completion(nil)
            return
        }
        try URLSession.liveQuery.connect(isUserWantsToConnect: true, task: task) { error in
            if error == nil {
                self.isConnecting = true
            }
        }
    }

    ///Manually disconnect from the `ParseLiveQuery` server.
    public func close(_ isUser: Bool = true) throws {
        if isConnected {
            task.cancel()
            if isUser {
                isDisconnectedByUser = true
            }
        }
        URLSession.liveQuery.delegates.removeValue(forKey: task)
    }

    func send(record: SubscriptionRecord, requestId: RequestId, completion: @escaping (Error?) -> Void) {
        self.pendingQueue.append((requestId, record))
        if isConnected {
            URLSession.liveQuery.send(record.messageData, task: task, completion: completion)
        }
    }
}

// MARK: SubscriptionRecord
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    class SubscriptionRecord {

        var messageData: Data
        var queryData: Data
        var subscriptionHandler: AnyObject
        var eventHandlerClosure: ((Data) -> Void)?
        var subscribeHandlerClosure: ((Bool) -> Void)?
        var unsubscribeHandlerClosure: (() -> Void)?

        init?<T: SubscriptionHandlable>(query: Query<T.Object>, message: SubscribeMessage<T.Object>, handler: T) {
            guard let queryData = try? ParseCoding.jsonEncoder().encode(query),
                  let encoded = try? ParseCoding.jsonEncoder().encode(message) else {
                return nil
            }
            self.queryData = queryData
            self.messageData = encoded
            self.subscriptionHandler = handler

            eventHandlerClosure = { event in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }

                try? handler.didReceive(event)
            }

            subscribeHandlerClosure = { (new) in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didSubscribe(new)
            }

            unsubscribeHandlerClosure = { () in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didUnsubscribe()
            }
        }

        func update<T: ParseObject>(query: Query<T>, message: SubscribeMessage<T>) throws {
            guard let queryData = try? ParseCoding.jsonEncoder().encode(query),
                  let encoded = try? ParseCoding.jsonEncoder().encode(message) else {
                throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Unable to update subscription.")
            }
            self.queryData = queryData
            self.messageData = encoded
        }
    }
}

// MARK: Subscribing
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func subscribe<T>(_ query: Query<T>) throws -> Subscription<Query<T>, T> {
        try subscribe(Subscription(query: query))
    }

    func subscribe<T>(_ handler: T) throws -> T where T: SubscriptionHandlable {

        let requestId = requestIdGenerator()
        let message = SubscribeMessage<T.Object>(operation: .subscribe, requestId: requestId, query: handler.query)
        guard let subscriptionRecord = SubscriptionRecord(
            query: handler.query,
            message: message,
            handler: handler
        ) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Couldn't create subscription.")
        }

        self.send(record: subscriptionRecord, requestId: requestId) { _ in }
        return handler
    }
}

// MARK: Unsubscribing
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func unsubscribe<T>(_ query: Query<T>) throws where T: ParseObject {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(query)
        try unsubscribe { $0.queryData == unsubscribeQuery }
    }

    func unsubscribe<T>(_ handler: T) throws where T: SubscriptionHandlable {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(handler.query)
        try unsubscribe { $0.queryData == unsubscribeQuery && $0.subscriptionHandler === handler }
    }

    func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) throws {
        try subscriptions.forEach { (key, value) -> Void in
            if matcher(value) {
                let encoded = try ParseCoding
                    .jsonEncoder()
                    .encode(StandardMessage(operation: .unsubscribe,
                                            requestId: key))
                let updatedRecord = value
                updatedRecord.messageData = encoded
                self.send(record: updatedRecord, requestId: key) { _ in }
            } else {
                let error = ParseError(code: .unknownError,
                                       message: "ParseLiveQuery Error: Not subscribed to this query")
                throw error
            }
        }
    }
}

// MARK: Updating
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func update<T>(_ handler: T) throws where T: SubscriptionHandlable {
        try subscriptions.forEach {(key, value) -> Void in
            if value.subscriptionHandler === handler {
                let message = SubscribeMessage<T.Object>(operation: .update, requestId: key, query: handler.query)
                let updatedRecord = value
                try updatedRecord.update(query: handler.query, message: message)
                self.send(record: updatedRecord, requestId: key) { _ in }
            }
        }

    }
}

// MARK: Query - Subscribe
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {
    /**
     Registers the query for live updates, using the default subscription handler,
     and the default `ParseLiveQuery` client.
     */
    var subscribe: Subscription<Query<T>, ResultType>? {
        try? ParseLiveQuery.client?.subscribe(self)
    }

    /**
     Registers the query for live updates, using the default subscription handler,
     and a specific `ParseLiveQuery` client.
     - parameter client: A specific client.
     - returns: The subscription that has just been registered
     */
    func subscribe(_ client: ParseLiveQuery) throws -> Subscription<Query<T>, ResultType> {
        try client.subscribe(Subscription(query: self))
    }

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler.
     - returns: Your subscription handler, for easy chaining.
    */
    static func subscribe<T: SubscriptionHandlable>(_ handler: T) throws -> T {
        if let client = ParseLiveQuery.client {
            return try client.subscribe(handler)
        } else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Not able to initialize client.")
        }
    }

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler.
     - parameter client: A specific client.
     - returns: Your subscription handler, for easy chaining.
    */
    static func subscribe<T: SubscriptionHandlable>(_ handler: T, client: ParseLiveQuery) throws -> T {
        try client.subscribe(handler)
    }
}

// MARK: Query - Unsubscribe
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {
    /**
     Unsubscribes all current subscriptions for a given query on the default
     `ParseLiveQuery` client.
     */
    func unsubscribe() throws {
        try ParseLiveQuery.client?.unsubscribe(self)
    }

    /**
     Unsubscribes all current subscriptions for a given query on a specific
     `ParseLiveQuery` client.
     - parameter client: A specific client.
     */
    func unsubscribe(client: ParseLiveQuery) throws {
        try client.unsubscribe(self)
    }

    /**
     Unsubscribes from a specific query-handler on the default
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     */
    func unsubscribe<T: SubscriptionHandlable>(_ handler: T) throws {
        try ParseLiveQuery.client?.unsubscribe(handler)
    }

    /**
     Unsubscribes from a specific query-handler on a specific
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - parameter client: A specific client.
     */
    func unsubscribe<T: SubscriptionHandlable>(_ handler: T, client: ParseLiveQuery) throws {
        try client.unsubscribe(handler)
    }
}

// MARK: Query - Update
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {
    /**
     Updates an existing subscription with a new query on the default `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     */
    func update<T: SubscriptionHandlable>(_ handler: T) throws {
        try ParseLiveQuery.client?.update(handler)
    }

    /**
     Updates an existing subscription with a new query on a specific `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - parameter client: A specific client.
     */
    func update<T: SubscriptionHandlable>(_ handler: T, client: ParseLiveQuery) throws {
        try client.update(handler)
    }
}
