//
//  SubscriptionCallback.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/24/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 A default implementation of the `QuerySubscribable` protocol using closures for callbacks.
 */
open class SubscriptionCallback<T: ParseObject>: QuerySubscribable {

    public var query: Query<T>
    public typealias Object = T
    fileprivate var eventHandlers = [(Query<T>, Event<T>) -> Void]()
    fileprivate var subscribeHandlers = [(Query<T>, Bool) -> Void]()
    fileprivate var unsubscribeHandlers = [(Query<T>) -> Void]()

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public required init(query: Query<T>) {
        self.query = query
    }

    /**
     Register a callback for when an event occurs.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleEvent(_ handler: @escaping (Query<T>,
                                                                   Event<T>) -> Void) -> SubscriptionCallback {
        eventHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a client successfully subscribes to a query.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleSubscribe(_ handler: @escaping (Query<T>,
                                                                       Bool) -> Void) -> SubscriptionCallback {
        subscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a query has been unsubscribed.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleUnsubscribe(_ handler: @escaping (Query<T>) -> Void) -> SubscriptionCallback {
        unsubscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when an event occurs of a specific type
     Example:
         subscription.handle(Event.Created) { query, object in
            // Called whenever an object is creaated
         }
     - parameter eventType: The event type to handle. You should pass one of the enum cases in `Event`.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult public func handle(_ eventType: @escaping (T) -> Event<T>,
                                          _ handler: @escaping (Query<T>, T) -> Void) -> SubscriptionCallback {
        return handleEvent { query, event in
            switch event {
            case .entered(let obj) where eventType(obj) == event: handler(query, obj)
            case .left(let obj)  where eventType(obj) == event: handler(query, obj)
            case .created(let obj) where eventType(obj) == event: handler(query, obj)
            case .updated(let obj) where eventType(obj) == event: handler(query, obj)
            case .deleted(let obj) where eventType(obj) == event: handler(query, obj)
            default: return
            }
        }
    }

    // MARK: QuerySubscribable

    open func didReceive(_ eventData: Data) throws {
        // Need to decode the event with respect to the `ParseObject`.
        let eventMessage = try ParseCoding.jsonDecoder().decode(EventResponse<T>.self, from: eventData)
        guard let event = Event(event: eventMessage) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Could not create event.")
        }
        eventHandlers.forEach { $0(query, event) }
    }

    open func didSubscribe(_ new: Bool) {
        subscribeHandlers.forEach { $0(query, new) }
    }

    open func didUnsubscribe() {
        unsubscribeHandlers.forEach { $0(query) }
    }
}
