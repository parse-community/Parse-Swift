//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class LiveQuerySocket: NSObject {
    let session: URLSession!
    var task: URLSessionWebSocketTask?
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()
    var isConnected = false

    override init() {
        super.init()
        
        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }

        if ParseConfiguration.liveQuerysServerURL == nil {
            ParseConfiguration.liveQuerysServerURL = ParseConfiguration.serverURL
        }

        guard var components = URLComponents(url: ParseConfiguration.liveQuerysServerURL, resolvingAgainstBaseURL: false) else {
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        ParseConfiguration.liveQuerysServerURL = components.url
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.task = session.webSocketTask(with: ParseConfiguration.liveQuerysServerURL)
        task?.resume()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        do {
            try LiveQuery.Command<NoBody,Bool>.connect().executeAsync(callbackQueue: .main) { result in
                switch result {
                
                case .success(let connected):
                    self.isConnected = connected
                case .failure(_):
                    self.isConnected = false
                }
            }
        } catch {
            
        }
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    // An opaque placeholder structed used to ensure that we type-safely create request IDs and don't shoot ourself in
    // the foot with array indexes.
    struct RequestId: Equatable {
        let value: Int

        init(value: Int) {
            self.value = value
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func connect() {

    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func diconnect() {
        task?.cancel()
        task = nil
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {

}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
    func readMessage() {
        guard let task = self.task else {
            return
        }

        task.receive { result in
            switch result {

            case .success(.data(let data)):
                //Decode data
                self.readMessage()
            case .success(.string(_)):
                print()
            case .success(_):
                print()
            case .failure(let error):
                print(error)
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension LiveQuerySocket {
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension URLSession {
    static let liveQuery = LiveQuerySocket()
}
