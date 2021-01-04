//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class ParseLiveQuery: NSObject {
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()
    var pendingSubscriptionData = [RequestId: Data]()
    public weak var delegate: ParseLiveQueryDelegate?

    public init(server: URL? = nil) {
        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }
        super.init()
        URLSession.liveQuery.delegate = self
    }

    deinit {
        if let currentDelegate = URLSession.liveQuery.delegate as? ParseLiveQuery {
            // Only remove delegate if in control of socket
            if currentDelegate == self {
                URLSession.liveQuery.delegate = nil
            }
        }
    }
}

// MARK: Delegate
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func connected() {
        //Try to send all pending data
        self.pendingSubscriptionData.forEach {(_, value) -> Void in
            URLSession.liveQuery.send(value) { _ in }
        }
    }

    func received(_ data: Data) {
        //Decode
        guard let decoded = try? ParseCoding.jsonDecoder().decode(NoBody.self, from: data) else {
            print("Couldn't decode \(data)")
            return
        }
        print(decoded)
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
        if let delegate = delegate {
            delegate.receivedChallenge(challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    #if !os(watchOS)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) {
        print()
    }
    #endif
}

// MARK: Connection
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    public func connect(completion: @escaping (Error?) -> Void) throws {
        try URLSession.liveQuery.connect(isUserWantsToConnect: true, completion: completion)
    }

    public func disconnect() {
        URLSession.liveQuery.diconnect()
    }

    private func send(data: Data, requestId: RequestId, completion: @escaping (Error?) -> Void) {
        self.pendingSubscriptionData[requestId] = data
        if URLSession.liveQuery.isLiveQueryConnected {
            URLSession.liveQuery.send(data, completion: completion)
        }
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
        var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
        message.query = query
        message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
        return try ParseCoding.jsonEncoder().encode(message)
    }
}
