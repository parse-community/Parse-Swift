//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 The `ParseLiveQuery` class enables two-way communication to a Parse Live Query
 Server.
 
 In most cases, you should not call this class directly as a LiveQuery can be indirectly
 created from `Query` using:
 ```swift
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
 ```
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
 When an instance is deinitialized it will automatically close it is connection gracefully.
 */
public final class ParseLiveQuery: NSObject {
    // Queues
    let synchronizationQueue: DispatchQueue
    let notificationQueue: DispatchQueue

    //Task
    var task: URLSessionWebSocketTask! {
        willSet {
            if newValue == nil && isSocketEstablished {
                isSocketEstablished = false
            }
        }
    }
    var url: URL!
    var clientId: String!
    var attempts: Int = 1 {
        willSet {
            if newValue >= ParseLiveQueryConstants.maxConnectionAttempts + 1 {
                let error = ParseError(code: .unknownError,
                                       message: """
ParseLiveQuery Error: Reached max attempts of
\(ParseLiveQueryConstants.maxConnectionAttempts).
Not attempting to open ParseLiveQuery socket anymore
""")
                notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
                close() // Quit trying to reconnect
            }
        }
    }
    var isDisconnectedByUser = false {
        willSet {
            if newValue {
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
            if !newValue {
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
        } else if let liveQueryConfigURL = Parse.configuration.liveQuerysServerURL {
            url = liveQueryConfigURL
        } else {
            url = Parse.configuration.serverURL
        }

        guard var components = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false) else {
            let error = ParseError(code: .unknownError,
                                   message: "ParseLiveQuery Error: Could not create components from url: \(url!)")
            throw error
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        url = components.url
        self.task = URLSession.liveQuery.createTask(self.url,
                                                    taskDelegate: self)
        self.resumeTask { _ in }
        if isDefault {
            Self.defaultClient = self
        }
    }

    /// Gracefully disconnects from the ParseLiveQuery Server.
    deinit {
        close(useDedicatedQueue: false)
        authenticationDelegate = nil
        receiveDelegate = nil
    }
}

// MARK: Client Intents
extension ParseLiveQuery {

    /// Current LiveQuery client.
    public private(set) static var client = try? ParseLiveQuery()

    func resumeTask(completion: @escaping (Error?) -> Void) {
        synchronizationQueue.sync {
            switch self.task.state {
            case .suspended:
                URLSession.liveQuery.receive(task)
                self.task.resume()
                completion(nil)
            case .completed, .canceling:
                let oldTask = self.task
                self.task = URLSession.liveQuery.createTask(self.url,
                                                            taskDelegate: self)
                self.task.resume()
                if let oldTask = oldTask {
                    URLSession.liveQuery.removeTaskFromDelegates(oldTask)
                }
                completion(nil)
            case .running:
                self.open(isUserWantsToConnect: false, completion: completion)
            @unknown default:
                break
            }
        }
    }

    func removePendingSubscription(_ requestId: Int) {
        self.pendingSubscriptions.removeAll(where: { $0.0.value == requestId })
        closeWebsocketIfNoSubscriptions()
    }

    func closeWebsocketIfNoSubscriptions() {
        self.notificationQueue.async {
            if self.subscriptions.isEmpty && self.pendingSubscriptions.isEmpty {
                self.close()
            }
        }
    }

    /// The default `ParseLiveQuery` client for all LiveQuery connections.
    class public var defaultClient: ParseLiveQuery? {
        get {
            Self.client
        }
        set {
            Self.client = nil
            Self.client = newValue
        }
    }

    /// Set a specific ParseLiveQuery client to be the default for all `ParseLiveQuery` connections.
    /// - parameter client: The client to set as the default.
    /// - warning: This will be removed in ParseSwift 5.0.0 in favor of `defaultClient`.
    @available(*, deprecated, renamed: "defaultClient")
    class public func setDefault(_ client: ParseLiveQuery) {
        Self.defaultClient = client
    }

    /// Get the default `ParseLiveQuery` client for all LiveQuery connections.
    /// - returns: The default `ParseLiveQuery` client.
    /// - warning: This will be removed in ParseSwift 5.0.0 in favor of `defaultClient`.
    @available(*, deprecated, renamed: "defaultClient")
    class public func getDefault() -> ParseLiveQuery? {
        Self.defaultClient
    }

    /// Check if a query has an active subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to verify.
    /// - returns: **true** if subscribed. **false** otherwise.
    /// - throws: An error of type `ParseError`.
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
    /// - returns: **true** if query is a pending subscription. **false** otherwise.
    /// - throws: An error of type `ParseError`.
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
    /// - throws: An error of type `ParseError`.
    public func removePendingSubscription<T: ParseObject>(_ query: Query<T>) throws {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        pendingSubscriptions.removeAll(where: { (_, value) -> Bool in
            self.closeWebsocketIfNoSubscriptions()
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }
}

// MARK: Delegate
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func status(_ status: LiveQuerySocket.Status,
                closeCode: URLSessionWebSocketTask.CloseCode? = nil,
                reason: Data? = nil) {
        synchronizationQueue.sync {
            switch status {

            case .open:
                self.isSocketEstablished = true
                self.open(isUserWantsToConnect: false) { _ in }
            case .closed:
                self.notificationQueue.async {
                    self.receiveDelegate?.closedSocket(closeCode, reason: reason)
                }
                self.isSocketEstablished = false
                if !self.isDisconnectedByUser {
                    // Try to reconnect
                    self.open(isUserWantsToConnect: false) { _ in }
                }
            }
        }
    }

    func received(_ data: Data) {
        synchronizationQueue.sync {
            if let redirect = try? ParseCoding.jsonDecoder().decode(RedirectResponse.self, from: data) {
                if redirect.op == .redirect {
                    self.url = redirect.url
                    if self.isConnected {
                        self.close(useDedicatedQueue: true)
                        //Try to reconnect
                        self.resumeTask { _ in }
                    }
                }
                return
            }

            //Check if this is an error response
            if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
                if !error.reconnect {
                    //Treat this as a user disconnect because the server does not want to hear from us anymore
                    self.close()
                }
                guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                    //Turn LiveQuery error into ParseError
                    let parseError = ParseError(code: .unknownError,
                                                // swiftlint:disable:next line_length
                                                message: "ParseLiveQuery Error: code: \(error.code), message: \(error.message)")
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
                    //If not connected, should not receive anything other than a connection response
                    guard let outOfOrderMessage = try? ParseCoding
                            .jsonDecoder()
                            .decode(AnyCodable.self, from: data) else {
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "ParseLiveQuery Error: Received message out of order, but could not decode it")
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

                    if let installationId = BaseParseInstallation.currentContainer.installationId {
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
                            self.subscriptions[subscribed.0] = subscribed.1
                            self.removePendingSubscription(subscribed.0.value)
                            self.notificationQueue.async {
                                subscribed.1.subscribeHandlerClosure?(isNew)
                            }
                        }
                    case .unsubscribed:
                        let requestId = RequestId(value: preliminaryMessage.requestId)
                        guard let subscription = self.subscriptions[requestId] else {
                            return
                        }
                        self.subscriptions.removeValue(forKey: requestId)
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
                    let error = ParseError(code: .unknownError,
                                           message: "ParseLiveQuery Error: Hit an undefined state.")
                    self.notificationQueue.async {
                        self.receiveDelegate?.received(error)
                    }
                }
            }
        }
    }

    func receivedError(_ error: Error) {
        if !isPosixError(error) {
            if !isURLError(error) {
                notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
            }
        }
    }

    func isPosixError(_ error: Error) -> Bool {
        guard let posixError = error as? POSIXError else {
            notificationQueue.async {
                self.receiveDelegate?.received(error)
            }
            return false
        }
        if posixError.code == .ENOTCONN {
            isSocketEstablished = false
            open(isUserWantsToConnect: false) { error in
                guard let error = error else {
                    // Resumed task successfully
                    return
                }
                self.notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
            }
        } else {
            notificationQueue.async {
                self.receiveDelegate?.received(error)
            }
        }
        return true
    }

    func isURLError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            notificationQueue.async {
                self.receiveDelegate?.received(error)
            }
            return false
        }
        if [-1001, -1005, -1011].contains(urlError.errorCode) {
            isSocketEstablished = false
            open(isUserWantsToConnect: false) { error in
                guard let error = error else {
                    // Resumed task successfully
                    return
                }
                self.notificationQueue.async {
                    self.receiveDelegate?.received(error)
                }
            }
        } else {
            notificationQueue.async {
                self.receiveDelegate?.received(error)
            }
        }
        return true
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
            } else if let parseAuthentication = Parse.sessionDelegate.authentication {
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
extension ParseLiveQuery {

    /// Manually establish a connection to the `ParseLiveQuery` Server.
    /// - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to **true**.
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
                        completion(error)
                    }
                } catch {
                    completion(error)
                }
            } else {
                self.synchronizationQueue
                    .asyncAfter(deadline: .now() + DispatchTimeInterval
                                    .seconds(URLSession.reconnectInterval(attempts))) {
                        self.attempts += 1
                        self.resumeTask { _ in }
                        let error = ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "ParseLiveQuery Error: attempted to open socket \(self.attempts) time(s)")
                        completion(error)
                }
            }
        }
    }

    /// Manually disconnect from the `ParseLiveQuery` Server.
    public func close() {
        synchronizationQueue.sync {
            if self.isConnected {
                self.task.cancel(with: .goingAway, reason: nil)
                self.isDisconnectedByUser = true
                let oldTask = self.task
                isSocketEstablished = false
                // Prepare new task for future use.
                self.task = URLSession.liveQuery.createTask(self.url,
                                                            taskDelegate: self)
                if let oldTask = oldTask {
                    URLSession.liveQuery.removeTaskFromDelegates(oldTask)
                }
            }
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
            if self.task.state == .running {
                URLSession.liveQuery.sendPing(task, pongReceiveHandler: pongReceiveHandler)
            } else {
                let error = ParseError(code: .unknownError,
                                       // swiftlint:disable:next line_length
                                       message: "ParseLiveQuery Error: socket status needs to be \"\(URLSessionTask.State.running.rawValue)\" before pinging server. Current status is \"\(self.task.state.rawValue)\". Try calling \"open()\" to change socket status.")
                pongReceiveHandler(error)
            }
        }
    }

    func close(useDedicatedQueue: Bool) {
        if useDedicatedQueue {
            synchronizationQueue.async {
                if self.isConnected {
                    self.task.cancel(with: .goingAway, reason: nil)
                    let oldTask = self.task
                    self.isSocketEstablished = false
                    // Prepare new task for future use.
                    self.task = URLSession.liveQuery.createTask(self.url,
                                                                taskDelegate: self)
                    if let oldTask = oldTask {
                        URLSession.liveQuery.removeTaskFromDelegates(oldTask)
                    }
                }
            }
        } else {
            if self.isConnected {
                self.task.cancel(with: .goingAway, reason: nil)
                let oldTask = task
                isSocketEstablished = false
                // Prepare new task for future use.
                self.task = URLSession.liveQuery.createTask(self.url,
                                                            taskDelegate: self)
                if let oldTask = oldTask {
                    URLSession.liveQuery.removeTaskFromDelegates(oldTask)
                }
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
extension ParseLiveQuery {
    class SubscriptionRecord {

        var messageData: Data
        var queryData: Data
        var subscriptionHandler: AnyObject
        var eventHandlerClosure: ((Data) -> Void)?
        var subscribeHandlerClosure: ((Bool) -> Void)?
        var unsubscribeHandlerClosure: (() -> Void)?

        init?<T: QuerySubscribable>(query: Query<T.Object>, message: SubscribeMessage<T.Object>, handler: T) {
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
extension ParseLiveQuery {

    func subscribe<T>(_ query: Query<T>) throws -> Subscription<T> {
        try subscribe(Subscription(query: query))
    }

    func subscribe<T>(_ query: Query<T>) throws -> SubscriptionCallback<T> {
        try subscribe(SubscriptionCallback(query: query))
    }

    public func subscribe<T>(_ handler: T) throws -> T where T: QuerySubscribable {

        let requestId = requestIdGenerator()
        let message = SubscribeMessage<T.Object>(operation: .subscribe,
                                                 requestId: requestId,
                                                 query: handler.query)
        guard let subscriptionRecord = SubscriptionRecord(
            query: handler.query,
            message: message,
            handler: handler
        ) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Could not create subscription.")
        }

        self.send(record: subscriptionRecord, requestId: requestId) { _ in }
        return handler
    }
}

// MARK: Unsubscribing
extension ParseLiveQuery {

    func unsubscribe<T>(_ query: Query<T>) throws where T: ParseObject {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(query)
        try unsubscribe { $0.queryData == unsubscribeQuery }
    }

    func unsubscribe<T>(_ handler: T) throws where T: QuerySubscribable {
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
            }
        }
    }
}

// MARK: Updating
extension ParseLiveQuery {

    func update<T>(_ handler: T) throws where T: QuerySubscribable {
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
     - returns: The subscription that has just been registered.
     - throws: An error of type `ParseError`.
     */
    func subscribe(_ client: ParseLiveQuery) throws -> Subscription<ResultType> {
        try client.subscribe(Subscription(query: self))
    }
    #endif

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler. 
     - returns: Your subscription handler, for easy chaining.
     - throws: An error of type `ParseError`.
    */
    static func subscribe<T: QuerySubscribable>(_ handler: T) throws -> T {
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
     - throws: An error of type `ParseError`.
    */
    static func subscribe<T: QuerySubscribable>(_ handler: T, client: ParseLiveQuery) throws -> T {
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
     - throws: An error of type `ParseError`.
     */
    func subscribeCallback(_ client: ParseLiveQuery) throws -> SubscriptionCallback<ResultType> {
        try client.subscribe(SubscriptionCallback(query: self))
    }
}

// MARK: ParseLiveQuery - Unsubscribe
public extension Query {
    /**
     Unsubscribes all current subscriptions for a given query on the default
     `ParseLiveQuery` client.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe() throws {
        try ParseLiveQuery.client?.unsubscribe(self)
    }

    /**
     Unsubscribes all current subscriptions for a given query on a specific
     `ParseLiveQuery` client.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe(client: ParseLiveQuery) throws {
        try client.unsubscribe(self)
    }

    /**
     Unsubscribes from a specific query-handler on the default
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe<T: QuerySubscribable>(_ handler: T) throws {
        try ParseLiveQuery.client?.unsubscribe(handler)
    }

    /**
     Unsubscribes from a specific query-handler on a specific
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe<T: QuerySubscribable>(_ handler: T, client: ParseLiveQuery) throws {
        try client.unsubscribe(handler)
    }
}

// MARK: ParseLiveQuery - Update
public extension Query {
    /**
     Updates an existing subscription with a new query on the default `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - throws: An error of type `ParseError`.
     */
    func update<T: QuerySubscribable>(_ handler: T) throws {
        try ParseLiveQuery.client?.update(handler)
    }

    /**
     Updates an existing subscription with a new query on a specific `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
    func update<T: QuerySubscribable>(_ handler: T, client: ParseLiveQuery) throws {
        try client.update(handler)
    }
}
#endif
