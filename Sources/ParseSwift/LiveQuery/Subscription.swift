//
//  Subscription.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
//

import Foundation

/**
 Represents an update on a specific object from the live query server.
 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T: ParseObject> {
    /// The object has been updated, and is now included in the query
    case entered(T)

    /// The object has been updated, and is no longer included in the query
    case left(T)

    /// The object has been created, and is a part of the query
    case created(T)

    /// The object has been updated, and is still a part of the query
    case updated(T)

    /// The object has been deleted, and is no longer included in the query
    case deleted(T)

    init<V>(event: Event<V>) {
        switch event {
        case .entered(let value as T): self = .entered(value)
        case .left(let value as T):    self = .left(value)
        case .created(let value as T): self = .created(value)
        case .updated(let value as T): self = .updated(value)
        case .deleted(let value as T): self = .deleted(value)
        default: fatalError()
        }
    }
}

private func == <T>(lhs: Event<T>, rhs: Event<T>) -> Bool {
    switch (lhs, rhs) {
    case (.entered(let obj1), .entered(let obj2)): return obj1 == obj2
    case (.left(let obj1), .left(let obj2)):       return obj1 == obj2
    case (.created(let obj1), .created(let obj2)): return obj1 == obj2
    case (.updated(let obj1), .updated(let obj2)): return obj1 == obj2
    case (.deleted(let obj1), .deleted(let obj2)): return obj1 == obj2
    default: return false
    }
}

/**
 A default implementation of the  SubscriptionHandlable protocol, using closures for callbacks.
 */
open class Subscription<T: ParseObject>: SubscriptionHandlable {
    public var query: Query<T>
    public typealias SubscribedObject = T
    fileprivate var errorHandlers: [(Query<T>, Error) -> Void] = []
    fileprivate var eventHandlers: [(Query<T>, Event<T>) -> Void] = []
    fileprivate var subscribeHandlers: [(Query<T>) -> Void] = []
    fileprivate var unsubscribeHandlers: [(Query<T>) -> Void] = []

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public init(query: Query<T>) {
        self.query = query
    }

    /**
     Register a callback for when an error occurs.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining
     */
    @discardableResult open func handleError(_ handler: @escaping (Query<T>, Error) -> Void) -> Subscription {
        errorHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when an event occurs.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleEvent(_ handler: @escaping (Query<T>, Event<T>) -> Void) -> Subscription {
        eventHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a client succesfully subscribes to a query.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleSubscribe(_ handler: @escaping (Query<T>) -> Void) -> Subscription {
        subscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a query has been unsubscribed.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleUnsubscribe(_ handler: @escaping (Query<T>) -> Void) -> Subscription {
        unsubscribeHandlers.append(handler)
        return self
    }

    open func didReceive(_ event: Event<T>, forQuery query: Query<T>) {
        eventHandlers.forEach { $0(query, event) }
    }

    open func didEncounter(_ error: Error, forQuery query: Query<T>) {
        errorHandlers.forEach { $0(query, error) }
    }

    open func didSubscribe(toQuery query: Query<T>) {
        subscribeHandlers.forEach { $0(query) }
    }

    open func didUnsubscribe(fromQuery query: Query<T>) {
        unsubscribeHandlers.forEach { $0(query) }
    }
}

extension Subscription {
    /**
     Register a callback for when an error occcurs of a specific type
     Example:
         subscription.handle(LiveQueryErrors.InvalidJSONError.self) { query, error in
             print(error)
          }
     - parameter errorType: The error type to register for
     - parameter handler:   The callback to register
     - returns: The same subscription, for easy chaining
     */
    @discardableResult public func handle<E: Error>(
        _ errorType: E.Type = E.self,
        _ handler: @escaping (Query<T>, E) -> Void
        ) -> Subscription {
            errorHandlers.append { query, error in
                if let error = error as? E {
                    handler(query, error)
                }
            }
            return self
    }

    /**
     Register a callback for when an event occurs of a specific type
     Example:
         subscription.handle(Event.Created) { query, object in
            // Called whenever an object is creaated
         }
     - parameter eventType: The event type to handle. You should pass one of the enum cases in `Event`
     - parameter handler:   The callback to register
     - returns: The same subscription, for easy chaining
     */
    @discardableResult public func handle(_ eventType: @escaping (T) -> Event<T>,
                                          _ handler: @escaping (Query<T>, T) -> Void) -> Subscription {
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
}
