//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 The `ParseLiveQuery` class enables two-way communication to a Parse Live Query
 Server.
 
 In most cases, you should not call this class directly as a LiveQuery can be indirectly
 created from `Query` using:
    
     // If "Message" is a "ParseObject"
     let myQuery = Message.query("from" == "parse")
     guard let subscription = myQuery.subscribe else {
         "Error subscribing..."
         return
     }
     subscription.handleSubscribe { subscribedQuery, isNew in

         //Handle the subscription however you like.
         if isNew {
             print("Successfully subscribed to new query \(subscribedQuery)")
         } else {
             print("Successfully updated subscription to new query \(subscribedQuery)")
         }
     }
 
 The above creates a `ParseLiveQuery` using either the `liveQueryServerURL` (if it has been set)
 or `serverURL` when using `ParseSwift.initialize`. All additional queries will be
 created in the same way. The times you will want to initialize a new `ParseLiveQuery` instance
 are:
 1. If you want to become a `ParseLiveQueryDelegate` to respond to authentification challenges
 and/or receive metrics and error messages for a `ParseLiveQuery`client.
 2. You have specific LiveQueries that need to subscribe to a server that have a different url than
 the default.
 3. You want to change the default url for all LiveQuery connections when the app is already
 running. Initializing new instances will create a new task/connection to the `ParseLiveQuery` server.
 When an instance is deinitialized it will automatically close it's connection gracefully.
 */
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public final class ParseLiveQuery: NSObject {
    // Queues
    let synchronizationQueue: DispatchQueue
    let notificationQueue: DispatchQueue

    //Task
    var task: URLSessionWebSocketTask! {
        willSet {
            if newValue == nil && isSocketEstablished == true {
                isSocketEstablished = false
            }
        }
    }
    var url: URL!
    var clientId: String!
    var attempts: Int = 1 {
        willSet {
            if newValue >= ParseLiveQueryConstants.maxConnectionAttempts + 1 {
                close() // Quit trying to reconnect
            }
        }
    }
    var isDisconnectedByUser = false {
        willSet {
            if newValue == true {
                isConnected = false
            }
        }
    }

    /// Have all `ParseLiveQuery` authentication challenges delegated to you. There can only
    /// be one of these for all `ParseLiveQuery` connections. The default is to
    /// delegate to the `authentication` call block passed to `ParseSwift.initialize`
    /// or if there is not one, delegate to the OS. Conforms to `ParseLiveQueryDelegate`.
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

    /// Have `ParseLiveQuery` connection metrics, errors, etc delegated to you. A delegate
    /// can be assigned to individual connections. Conforms to `ParseLiveQueryDelegate`.
    public weak var receiveDelegate: ParseLiveQueryDelegate?

    /// True if the connection to the url is up and available. False otherwise.
    public internal(set) var isSocketEstablished = false { //URLSession has an established socket
        willSet {
            if newValue == false {
                isConnected = newValue
            }
        }
    }

    /// True if this client is connected. False otherwise.
    public internal(set) var isConnected = false {
        willSet {
            isConnecting = false
            if newValue {
                if isSocketEstablished {
                    if let task = self.task {
                        attempts = 1

                        //Resubscribe to all subscriptions by moving them in front of pending
                        var tempPendingSubscriptions = [(RequestId, SubscriptionRecord)]()
                        self.subscriptions.forEach { (key, value) -> Void in
                            tempPendingSubscriptions.append((key, value))
                        }
                        self.subscriptions.removeAll()
                        tempPendingSubscriptions.append(contentsOf: pendingSubscriptions)
                        pendingSubscriptions = tempPendingSubscriptions

                        //Send all pending messages in order
                        self.pendingSubscriptions.forEach {
                            let messageToSend = $0
                            URLSession.liveQuery.send(messageToSend.1.messageData, task: task) { _ in }
                        }
                    }
                }
            } else {
                clientId = nil
            }
        }
        didSet {
            if !isSocketEstablished {
                self.isConnected = false
            }
        }
    }

    /// True if this client is connecting. False otherwise.
    public internal(set) var isConnecting = false {
        didSet {
            if !isSocketEstablished {
                self.isConnecting = false
            }
        }
    }

    //Subscription
    let requestIdGenerator: () -> RequestId
    var subscriptions = [RequestId: SubscriptionRecord]()
    var pendingSubscriptions = [(RequestId, SubscriptionRecord)]() // Behave as FIFO to maintain sending order

    /**
     - parameter serverURL: The URL of the `ParseLiveQuery` Server to connect to.
     Defaults to `nil` in which case, it will use the URL passed in
     `ParseSwift.initialize(...liveQueryServerURL: URL)`. If no URL was passed,
     this assumes the current Parse Server URL is also the LiveQuery server.
     - parameter isDefault: Set this `ParseLiveQuery` client as the default client for all LiveQuery connections.
     Defaults value of false.
     - parameter notificationQueue: The queue to return to for all delegate notifications. Default value of .main.
     */
    public init(serverURL: URL? = nil, isDefault: Bool = false, notificationQueue: DispatchQueue = .main) throws {
        self.notificationQueue = notificationQueue
        synchronizationQueue = DispatchQueue(label: "com.parse.liveQuery.\(UUID().uuidString)",
                                             qos: .default,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)

        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }
        super.init()

        if let userSuppliedURL = serverURL {
            url = userSuppliedURL
        } else if let liveQueryConfigURL = ParseSwift.configuration.liveQuerysServerURL {
            url = liveQueryConfigURL
        } else {
            url = ParseSwift.configuration.serverURL
        }

        guard var components = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false) else {
            let error = ParseError(code: .unknownError,
                                   message: "ParseLiveQuery Error: couldn't create components from url: \(url!)")
            throw error
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        url = components.url
        self.createTask()

        if isDefault {
            Self.setDefault(self)
        }
    }

    /// Gracefully disconnects from the ParseLiveQuery Server.
    deinit {
        close(useDedicatedQueue: false)
        authenticationDelegate = nil
        receiveDelegate = nil
        if task != nil {
            URLSession.liveQuery.delegates.removeValue(forKey: task)
        } else {
            task = nil
        }
    }
}

// MARK: Helpers
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    /// Current LiveQuery client.
    public private(set) static var client = try? ParseLiveQuery()

    var reconnectInterval: Int {
        let min = NSDecimalNumber(decimal: Swift.min(30, pow(2, attempts) - 1))
        return Int.random(in: 0 ..< Int(truncating: min))
    }

    func createTask() {
        synchronizationQueue.sync {
            if self.task == nil {
                self.task = URLSession.liveQuery.createTask(self.url)
            }
            self.task.resume()
            URLSession.liveQuery.receive(self.task)
            URLSession.liveQuery.delegates[self.task] = self
        }
    }

    func removePendingSubscription(_ requestId: Int) {
        let requestIdToRemove = RequestId(value: requestId)
        self.pendingSubscriptions.removeAll(where: { $0.0.value == requestId })
        //Remove in subscriptions just in case the server
        //responded before this was called
        self.subscriptions.removeValue(forKey: requestIdToRemove)
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
        return pendingSubscriptions.contains(where: { (_, value) -> Bool in
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
        pendingSubscriptions.removeAll(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }
}

// MARK: Delegate
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func status(_ status: LiveQuerySocket.Status) {
        switch status {

        case .open:
            self.isSocketEstablished = true
            self.open(isUserWantsToConnect: false) { _ in }
        case .closed:
            self.isSocketEstablished = false
            if !self.isDisconnectedByUser {
                //Try to reconnect
                self.createTask()
            }
        }
    }

    func received(_ data: Data) {
        if let redirect = try? ParseCoding.jsonDecoder().decode(RedirectResponse.self, from: data) {
            if redirect.op == .redirect {
                self.url = redirect.url
                if self.isConnected {
                    self.close(useDedicatedQueue: true)
                    //Try to reconnect
                    self.createTask()
                }
            }
            return
        }

        //Check if this is an error response
        if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
            if !error.reconnect {
                //Treat this as a user disconnect because the server doesn't want to hear from us anymore
                self.close()
            }
            guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                //Turn LiveQuery error into ParseError
                let parseError = ParseError(code: .unknownError,
                                            message: "LiveQuery error code: \(error.code) message: \(error.error)")
                self.notificationQueue.async {
                    self.receiveDelegate?.received(parseError)
                }
                return
            }
            self.notificationQueue.async {
                self.receiveDelegate?.received(parseError)
            }
            return
        } else if !self.isConnected {
            //Check if this is a connected response
            guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                  response.op == .connected else {
                //If not connected, shouldn't receive anything other than a connection response
                guard let outOfOrderMessage = try? ParseCoding
                        .jsonDecoder()
                        .decode(AnyCodable.self, from: data) else {
                    let error = ParseError(code: .unknownError,
                                           // swiftlint:disable:next line_length
                                           message: "ParseLiveQuery Error: Received message out of order, but couldn't decode it")
                    self.notificationQueue.async {
                        self.receiveDelegate?.received(error)
                    }
                    return
                }
                let error = ParseError(code: .unknownError,
                                       // swiftlint:disable:next line_length
                                       message: "ParseLiveQuery Error: Received message out of order: \(outOfOrderMessage)")
                self.notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
                return
            }
            self.clientId = response.clientId
            self.isConnected = true
        } else {

            if let preliminaryMessage = try? ParseCoding.jsonDecoder()
                        .decode(PreliminaryMessageResponse.self,
                                from: data) {

                if preliminaryMessage.clientId != self.clientId {
                    let error = ParseError(code: .unknownError,
                                           // swiftlint:disable:next line_length
                                           message: "ParseLiveQuery Error: Received a message from a server who sent clientId \(preliminaryMessage.clientId) while it should be \(String(describing: self.clientId)). Not accepting message...")
                    self.notificationQueue.async {
                        self.receiveDelegate?.received(error)
                    }
                }

                if let installationId = BaseParseInstallation.currentInstallationContainer.installationId {
                    if installationId != preliminaryMessage.installationId {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "ParseLiveQuery Error: Received a message from a server who sent an installationId of \(String(describing: preliminaryMessage.installationId)) while it should be \(installationId). Not accepting message...")
                        self.notificationQueue.async {
                            self.receiveDelegate?.received(error)
                        }
                    }
                }

                switch preliminaryMessage.op {
                case .subscribed:

                    if let subscribed = self.pendingSubscriptions
                        .first(where: { $0.0.value == preliminaryMessage.requestId }) {
                        let requestId = RequestId(value: preliminaryMessage.requestId)
                        let isNew: Bool!
                        if self.subscriptions[requestId] != nil {
                            isNew = false
                        } else {
                            isNew = true
                        }
                        self.removePendingSubscription(subscribed.0.value)
                        self.subscriptions[subscribed.0] = subscribed.1
                        self.notificationQueue.async {
                            subscribed.1.subscribeHandlerClosure?(isNew)
                        }
                    }
                case .unsubscribed:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = self.subscriptions[requestId] else {
                        return
                    }
                    self.removePendingSubscription(preliminaryMessage.requestId)
                    self.notificationQueue.async {
                        subscription.unsubscribeHandlerClosure?()
                    }
                case .create, .update, .delete, .enter, .leave:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = self.subscriptions[requestId] else {
                        return
                    }
                    self.notificationQueue.async {
                        subscription.eventHandlerClosure?(data)
                    }
                default:
                    let error = ParseError(code: .unknownError,
                                           message: "ParseLiveQuery Error: Hit an undefined state.")
                    self.notificationQueue.async {
                        self.receiveDelegate?.received(error)
                    }
                }

            } else {
                let error = ParseError(code: .unknownError, message: "ParseLiveQuery Error: Hit an undefined state.")
                self.notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
            }
        }
    }

    func receivedError(_ error: ParseError) {
        notificationQueue.async {
            self.receiveDelegate?.received(error)
        }
    }

    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?) {
        notificationQueue.async {
            self.receiveDelegate?.receivedUnsupported(data, socketMessage: socketMessage)
        }
    }

    func received(challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                URLCredential?) -> Void) {
        notificationQueue.async {
            if let delegate = self.authenticationDelegate {
                delegate.received(challenge, completionHandler: completionHandler)
            } else if let parseAuthentication = ParseSwift.sessionDelegate.authentication {
                parseAuthentication(challenge, completionHandler)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    #if !os(watchOS)
    func received(_ metrics: URLSessionTaskTransactionMetrics) {
        notificationQueue.async {
            self.receiveDelegate?.received(metrics)
        }
    }
    #endif
}

// MARK: Connection
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    /// Manually establish a connection to the `ParseLiveQuery` Server.
    /// - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to `true`.
    /// - parameter completion: Returns `nil` if successful, an `Error` otherwise.
    public func open(isUserWantsToConnect: Bool = true, completion: @escaping (Error?) -> Void) {
        synchronizationQueue.sync {
            if isUserWantsToConnect {
                self.isDisconnectedByUser = false
            }
            if self.isConnected || self.isDisconnectedByUser {
                completion(nil)
                return
            }
            if self.isConnecting {
                completion(nil)
                return
            }
            if isSocketEstablished {
                do {
                    try URLSession.liveQuery.connect(task: self.task) { error in
                        if error == nil {
                            self.isConnecting = true
                        }
                    }
                    completion(nil)
                } catch {
                    completion(error)
                }
            } else {
                self.synchronizationQueue
                    .asyncAfter(deadline: .now() + DispatchTimeInterval
                                    .seconds(reconnectInterval)) {
                    self.createTask()
                    self.attempts += 1
                    let error = ParseError(code: .unknownError,
                                           message: "Attempted to open socket \(self.attempts)")
                    completion(error)
                }
            }
        }
    }

    /// Manually disconnect from the `ParseLiveQuery` Server.
    public func close() {
        synchronizationQueue.sync {
            if self.isConnected {
                self.task.cancel()
                self.isDisconnectedByUser = true
            }
            if task != nil {
                URLSession.liveQuery.delegates.removeValue(forKey: self.task)
            }
            self.task = nil
        }
    }

    /// Manually disconnect all sessions and subscriptions from the `ParseLiveQuery` Server.
    public func closeAll() {
        synchronizationQueue.sync {
            URLSession.liveQuery.closeAll()
        }
    }

    /**
     Sends a ping frame from the client side, with a closure to receive the pong from the server endpoint.
     - parameter pongReceiveHandler: A closure called by the task when it receives the pong
     from the server. The closure receives an  `Error` that indicates a lost connection or other problem,
     or nil if no error occurred.
     */
    public func sendPing(pongReceiveHandler: @escaping (Error?) -> Void) {
        synchronizationQueue.sync {
            URLSession.liveQuery.sendPing(task, pongReceiveHandler: pongReceiveHandler)
        }
    }

    func close(useDedicatedQueue: Bool) {
        if useDedicatedQueue {
            synchronizationQueue.async {
                if self.isConnected {
                    self.task.cancel()
                }
                URLSession.liveQuery.delegates.removeValue(forKey: self.task)
            }
        } else {
            if self.isConnected {
                self.task.cancel()
            }
            if self.task != nil {
                URLSession.liveQuery.delegates.removeValue(forKey: self.task)
            }
        }
    }

    func send(record: SubscriptionRecord, requestId: RequestId, completion: @escaping (Error?) -> Void) {
        synchronizationQueue.sync {
            self.pendingSubscriptions.append((requestId, record))
            if self.isConnected {
                URLSession.liveQuery.send(record.messageData, task: self.task, completion: completion)
            } else {
                self.open(completion: completion)
            }
        }
    }
}

// MARK: SubscriptionRecord
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    class SubscriptionRecord {

        var messageData: Data
        var queryData: Data
        var subscriptionHandler: AnyObject
        var eventHandlerClosure: ((Data) -> Void)?
        var subscribeHandlerClosure: ((Bool) -> Void)?
        var unsubscribeHandlerClosure: (() -> Void)?

        init?<T: ParseSubscription>(query: Query<T.Object>, message: SubscribeMessage<T.Object>, handler: T) {
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
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func subscribe<T>(_ query: Query<T>) throws -> Subscription<T> {
        try subscribe(Subscription(query: query))
    }

    func subscribe<T>(_ query: Query<T>) throws -> SubscriptionCallback<T> {
        try subscribe(SubscriptionCallback(query: query))
    }

    func subscribe<T>(_ handler: T) throws -> T where T: ParseSubscription {

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
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func unsubscribe<T>(_ query: Query<T>) throws where T: ParseObject {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(query)
        try unsubscribe { $0.queryData == unsubscribeQuery }
    }

    func unsubscribe<T>(_ handler: T) throws where T: ParseSubscription {
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
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {

    func update<T>(_ handler: T) throws where T: ParseSubscription {
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

// MARK: ParseLiveQuery - Subscribe
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {
    #if canImport(Combine)
    /**
     Registers the query for live updates, using the default subscription handler,
     and the default `ParseLiveQuery` client. Suitable for `ObjectObserved`
     as the subscription can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     */
    var subscribe: Subscription<ResultType>? {
        try? ParseLiveQuery.client?.subscribe(self)
    }

    /**
     Registers the query for live updates, using the default subscription handler,
     and a specific `ParseLiveQuery` client. Suitable for `ObjectObserved`
     as the subscription can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - parameter client: A specific client.
     - returns: The subscription that has just been registered
     */
    func subscribe(_ client: ParseLiveQuery) throws -> Subscription<ResultType> {
        try client.subscribe(Subscription(query: self))
    }
    #endif

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler. 
     - returns: Your subscription handler, for easy chaining.
    */
    static func subscribe<T: ParseSubscription>(_ handler: T) throws -> T {
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
    static func subscribe<T: ParseSubscription>(_ handler: T, client: ParseLiveQuery) throws -> T {
        try client.subscribe(handler)
    }

    /**
     Registers the query for live updates, using the default subscription handler,
     and the default `ParseLiveQuery` client.
     */
    var subscribeCallback: SubscriptionCallback<ResultType>? {
        try? ParseLiveQuery.client?.subscribe(self)
    }

    /**
     Registers the query for live updates, using the default subscription handler,
     and a specific `ParseLiveQuery` client.
     - parameter client: A specific client.
     - returns: The subscription that has just been registered.
     */
    func subscribeCallback(_ client: ParseLiveQuery) throws -> SubscriptionCallback<ResultType> {
        try client.subscribe(SubscriptionCallback(query: self))
    }
}

// MARK: ParseLiveQuery - Unsubscribe
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
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
    func unsubscribe<T: ParseSubscription>(_ handler: T) throws {
        try ParseLiveQuery.client?.unsubscribe(handler)
    }

    /**
     Unsubscribes from a specific query-handler on a specific
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - parameter client: A specific client.
     */
    func unsubscribe<T: ParseSubscription>(_ handler: T, client: ParseLiveQuery) throws {
        try client.unsubscribe(handler)
    }
}

// MARK: ParseLiveQuery - Update
@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
public extension Query {
    /**
     Updates an existing subscription with a new query on the default `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     */
    func update<T: ParseSubscription>(_ handler: T) throws {
        try ParseLiveQuery.client?.update(handler)
    }

    /**
     Updates an existing subscription with a new query on a specific `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - parameter client: A specific client.
     */
    func update<T: ParseSubscription>(_ handler: T, client: ParseLiveQuery) throws {
        try client.update(handler)
    }
}
#endif
