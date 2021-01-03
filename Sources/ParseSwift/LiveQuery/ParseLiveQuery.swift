//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct ParseLiveQuery {
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()
    
    init() {
        URLSession.liveQuery.delegate = self
        
        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func received(_ data: Data) {
        //Decode
        print(data)
    }

    func receivedError(_ error: ParseError) {
        print(error)
    }
    
    func receivedUnsupported(_ string: String?, socketMessage: URLSessionWebSocketTask.Message?) {
        print()
    }
    
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) {
        print()
    }
}


// MARK: Connection
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ParseLiveQuery {
    func connect(completion: (Error?) -> Void) throws {
        try URLSession.liveQuery.connect(isUserWantsToConnect: true, completion: completion)
    }

    func disconnect() {
        URLSession.liveQuery.diconnect()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ParseLiveQuery {
    // An opaque placeholder structed used to ensure that we type-safely create request IDs and don't shoot ourself in
    // the foot with array indexes.
    struct RequestId: Equatable {
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

            errorHandlerClosure = { error, client in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didEncounter(error, forQuery: query)
            }

            subscribeHandlerClosure = { client in
                guard let handler = self.subscriptionHandler as? T else {
                    return
                }
                handler.didSubscribe(toQuery: query)
            }

            unsubscribeHandlerClosure = { client in
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
    func subscribe<T>(
        _ query: Query<T>,
        subclassType: T.Type = T.self
        ) -> Subscription<T> {
        return subscribe(query, handler: Subscription<T>())
    }

    /**
     Registers a query for live updates, using a custom subscription handler
     - parameter query:   The query to register for updates.
     - parameter handler: A custom subscription handler.
     - returns: Your subscription handler, for easy chaining.
    */
    func subscribe<T>(
        _ query: Query<T.SubscribedObject>,
        handler: T
        ) -> T where T:  SubscriptionHandlable {
        let subscriptionRecord = SubscriptionRecord(
            query: query,
            requestId: requestIdGenerator(),
            handler: handler
        )
        
        self.subscriptions.append(subscriptionRecord)

        if socket != nil {
            _ = self.sendOperation(.subscribe(requestId: subscriptionRecord.requestId, query: query as! Query<T>,
            sessionToken: PFUser.current()?.sessionToken))
        } else if !self.userDisconnected {
            self.reconnect()
            self.subscriptions.removeLast()
            return self.subscribe(query, handler: handler)
        } else {
            NSLog("LiveQuerySocket: Warning: The client was explicitly disconnected! You must explicitly call .reconnect() in order to process your subscriptions.")
        }
        
        return handler
    }

    /**
     Updates an existing subscription with a new query.
     Upon completing the registration, the subscribe handler will be called with the new query
     - parameter handler: The specific handler to update.
     - parameter query:   The new query for that handler.
     */
    func update<T>(
        _ handler: T,
        toQuery query: Query<T.SubscribedObject>
        ) where T:  SubscriptionHandlable {
        subscriptions = subscriptions.map {
            if $0.subscriptionHandler === handler {
                _ = sendOperation(.update(requestId: $0.requestId, query: query as! Query<ParseObject>))
                return SubscriptionRecord(query: query, requestId: $0.requestId, handler: $0.subscriptionHandler as! T)
            }
            return $0
        }
    }

    /**
     Unsubscribes all current subscriptions for a given query.
     - parameter query: The query to unsubscribe from.
     */
    func unsubscribe<T>(_ query: Query<T>) where T:  SubscriptionHandlable {
        unsubscribe { $0.query == query }
    }

    /**
     Unsubscribes from a specific query-handler pair.
     - parameter query:   The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    func unsubscribe<T>(_ query: Query<T.SubscribedObject>, handler: T) where T:  SubscriptionHandlable {
        unsubscribe { $0.query == query && $0.subscriptionHandler === handler }
    }

    func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) {
        var temp = [SubscriptionRecord]()
        subscriptions.forEach {
            if matcher($0) {
                _ = sendOperation(.unsubscribe(requestId: $0.requestId))
            } else {
                temp.append($0)
            }
        }
        subscriptions = temp
    }
}


static func subscribe<T: ParseObject>(_ query: Query<T>, requestId: Int) throws -> Data {
    var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
    message.query = query
    message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
    return try ParseCoding.jsonEncoder().encode(message)
}

static func update<T: ParseObject>(_ query: Query<T>, requestId: Int) throws -> Data {
    var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
    message.query = query
    message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
    return try ParseCoding.jsonEncoder().encode(message)
}

static func unsubscribe(_ requestId: Int) throws -> Data {
    try ParseCoding.jsonEncoder().encode(StandardMessage(operation: .unsubscribe, requestId: requestId))
}
