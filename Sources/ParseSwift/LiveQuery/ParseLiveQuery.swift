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
    public weak var metricsDelegate: ParseLiveQueryDelegate?
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
                    self.pendingSubscriptionData.forEach {(_, value) -> Void in
                        URLSession.liveQuery.send(value, task: task) { _ in }
                    }
                }
            }
        }
    }
    public internal(set) var isConnecting = false

    //Subscription
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()
    var pendingSubscriptionData = [RequestId: Data]()

    /**
     - parameter serverURL: The URL of the Parse Live Query Server to connect to.
     Defaults to `nil` in which case, it will use the URL passed in
     `ParseSwift.initialize(...liveQueryServerURL: URL)`. If no URL was passed,
     this assumes the current Parse Server URL is also the LiveQuery server.
     */
    public init?(serverURL: URL? = nil) {

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
        setupTask(true)
    }

    /// Gracefully disconnects from the ParseLiveQuery Server.
    deinit {
        if let task = self.task {
            try? disconnect()
            authenticationDelegate = nil
            metricsDelegate = nil
            URLSession.liveQuery.delegates.removeValue(forKey: task)
        }
    }

    func setupTask(_ forFirstTime: Bool = false) {
        if !forFirstTime {
            if task != nil {
                return
            }
        }
        task = URLSession.liveQuery.setupTask(url)
        task.resume()
        URLSession.liveQuery.receive(task)
        URLSession.liveQuery.delegates[task] = self
    }
}

// MARK: Delegate
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func status(_ status: LiveQuerySocketStatus) {
        switch status {

        case .open:
            isSocketEstablished = true
            try? connect(isUserWantsToConnect: false) { _ in }
        case .closed:
            isConnected = false
        }
    }

    func received(_ data: Data) {

        if !self.isConnected {
            //Check if this is a connected response
            guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                  response.op == .connected else {
                //If not connected, shouldn't be receiving anything other than connection response
                guard let outOfOrderMessage = try? ParseCoding
                        .jsonDecoder()
                        .decode(NoBody.self, from: data) else {
                    print("LiveQuery: Received message out of order, but couldn't decode it")
                    return
                }
                print("LiveQuery: Received message out of order: \(outOfOrderMessage)")
                return
            }
            self.isConnected = true
        } else {

            //Check if this is a error response
            if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
                if !error.reconnect {
                    //Treat this as a user disconnect because the server doesn't want to hear from us anymore
                    try? self.disconnect()
                    return
                }
                guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                    //Turn LiveQuery error into ParseError
                    let parseError = ParseError(code: .unknownError,
                                                message: "LiveQuery error code: \(error.code) message: \(error.error)")
                    print(parseError)
                    return
                }
                print(parseError)
            } else if let preliminaryMessage = try? ParseCoding.jsonDecoder()
                        .decode(PreliminaryMessageResponse.self,
                                from: data) {

                //Delegate all other messages to ParseLiveQuery to interpret
                print(preliminaryMessage)
                if let message = try? ParseCoding.jsonDecoder().decode(AnyCodable.self, from: data) {
                    print(message)
                }
            } else {
                print("Something went wrong")
                if let message = try? ParseCoding.jsonDecoder().decode(AnyCodable.self, from: data) {
                    print(message)
                }

            }
        }
    }

    func receivedError(_ error: ParseError) {
        print(error)
    }

    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?) {
        print("\(String(describing: data)) \(String(describing: socketMessage))")
    }

    func receivedChallenge(challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                         URLCredential?) -> Void) {
        if let delegate = authenticationDelegate {
            delegate.receivedChallenge(challenge, completionHandler: completionHandler)
        } else if let parseAuthentication = ParseConfiguration.sessionDelegate.authentication {
            parseAuthentication(challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    #if !os(watchOS)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) {
        metricsDelegate?.receivedMetrics(metrics)
    }
    #endif
}

// MARK: Connection
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    ///Manually establish a connection to the `ParseLiveQuery` server.
    public func connect(isUserWantsToConnect: Bool = true, completion: @escaping (Error?) -> Void) throws {
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
    public func disconnect() throws {
        if isConnected {
            task.cancel()
            isDisconnectedByUser = true
        }
        URLSession.liveQuery.delegates.removeValue(forKey: task)
    }

    private func send(data: Data, requestId: RequestId, completion: @escaping (Error?) -> Void) {
        if !isConnected {
            let error = ParseError(code: .unknownError, message: "LiveQuery: Not connected")
            completion(error)
            return
        }
        self.setupTask()
        self.pendingSubscriptionData[requestId] = data
        URLSession.liveQuery.send(data, task: task, completion: completion)
    }
}

// MARK: RequestId Generator
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    // An opaque placeholder structed used to ensure that we type-safely create request IDs and don't shoot ourself in
    // the foot with array indexes.
    struct RequestId: Hashable, Equatable {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

// MARK: SubscriptionRecord
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    class SubscriptionRecord {

        let requestId: RequestId

        //let query: Query<T.SubscribedObject>

        var subscriptionHandler: AnyObject
        //var eventHandlerClosure: ((Event<ParseObject>, LiveQuerySocket) -> Void)?
        var errorHandlerClosure: ((Error, LiveQuerySocket) -> Void)?
        var subscribeHandlerClosure: ((LiveQuerySocket) -> Void)?
        var unsubscribeHandlerClosure: ((LiveQuerySocket) -> Void)?

        init<T: SubscriptionHandlable>(query: Query<T.SubscribedObject>, requestId: RequestId, handler: T) {
            //self.query = query
            self.requestId = requestId
            self.subscriptionHandler = handler

            /*
            eventHandlerClosure = { event, client in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }

                handler.didReceive(Event<T.SubscribedObject>(event: event), forQuery: query, inClient: client)
            }*/

            errorHandlerClosure = { error, _ in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didEncounter(error, forQuery: query)
            }

            subscribeHandlerClosure = { _ in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didSubscribe(toQuery: query)
            }

            unsubscribeHandlerClosure = { _ in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didUnsubscribe(fromQuery: query)
            }
        }
    }
}

// MARK: Subscribing
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseLiveQuery {
    /**
     Registers a query for live updates, using the default subscription handler
     - parameter query:        The query to register for updates.
     - parameter subclassType: The subclass of ParseObject to be used as the type of the Subscription.
     This parameter can be automatically inferred from context most of the time
     - returns: The subscription that has just been registered
     */
    /*func subscribe<T>(
        _ query: Query<T>,
        subclassType: T.Type = T.self
        ) -> Subscription<T> {
        return subscribe(query, handler: Subscription<T>())
    }*/

    /**
     Registers a query for live updates, using a custom subscription handler
     - parameter query: The query to register for updates.
     - parameter handler: A custom subscription handler.
     - returns: Your subscription handler, for easy chaining.
    */
    func subscribe<T>(
        _ query: Query<T.SubscribedObject>,
        handler: T) throws -> T where T: SubscriptionHandlable {
        if !isConnected {
            throw ParseError(code: .unknownError,
                             message: "Currently not connected to the ParseLiveQueryServer.")
        }
        let requestId = requestIdGenerator()
        let subscriptionRecord = SubscriptionRecord(
            query: query,
            requestId: requestId,
            handler: handler
        )
        self.subscriptions.append(subscriptionRecord)

        var message = ParseMessage<T.SubscribedObject>(operation: .subscribe, requestId: requestId.value)
        message.query = query
        message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
        let encoded = try ParseCoding.jsonEncoder().encode(message)
        self.send(data: encoded, requestId: requestId) { _ in }
        return handler
    }
}

// MARK: Unsubscribing
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseLiveQuery {
    /**
     Unsubscribes all current subscriptions for a given query.
     - parameter query: The query to unsubscribe from.
     */
    /*func unsubscribe<T>(_ query: Query<T>) where T: SubscriptionHandlable {
        unsubscribe { $0.query == query }
    }

    /**
     Unsubscribes from a specific query-handler pair.
     - parameter query:   The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    func unsubscribe<T>(_ query: Query<T.SubscribedObject>, handler: T) where T:  SubscriptionHandlable {
        unsubscribe { $0.query == query && $0.subscriptionHandler === handler }
    }*/

    internal func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) throws {
        if !isConnected {
            throw ParseError(code: .unknownError,
                             message: "Currently not connected to the ParseLiveQueryServer.")
        }
        var temp = [SubscriptionRecord]()
        try subscriptions.forEach {
            if matcher($0) {
                let encoded = try ParseCoding
                    .jsonEncoder()
                    .encode(StandardMessage(operation: .unsubscribe,
                                            requestId: $0.requestId.value))
                self.send(data: encoded, requestId: $0.requestId) { _ in }
            } else {
                temp.append($0)
            }
        }
        subscriptions = temp
    }
}

// MARK: Updating
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseLiveQuery {
    /**
     Updates an existing subscription with a new query.
     Upon completing the registration, the subscribe handler will be called with the new query
     - parameter handler: The specific handler to update.
     - parameter query:   The new query for that handler.
     */
    func update<T>(
        _ handler: T,
        toQuery query: Query<T.SubscribedObject>
        ) throws where T: SubscriptionHandlable {
        if !isConnected {
            throw ParseError(code: .unknownError,
                             message: "Currently not connected to the ParseLiveQueryServer.")
        }
        subscriptions = try subscriptions.compactMap {
            if $0.subscriptionHandler === handler {
                var message = ParseMessage<T.SubscribedObject>(operation: .subscribe, requestId: $0.requestId.value)
                message.query = query
                message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
                let encoded = try ParseCoding.jsonEncoder().encode(message)
                self.send(data: encoded, requestId: $0.requestId) { _ in }
                guard let handler = $0.subscriptionHandler as? T else {
                    return nil
                }
                return SubscriptionRecord(query: query, requestId: $0.requestId, handler: handler)
            }
            return $0
        }
    }

    func update<T: ParseObject>(_ query: Query<T>, requestId: Int) throws -> Data {
        if !isConnected {
            throw ParseError(code: .unknownError,
                             message: "Currently not connected to the ParseLiveQueryServer.")
        }
        var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
        message.query = query
        message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
        return try ParseCoding.jsonEncoder().encode(message)
    }
}
