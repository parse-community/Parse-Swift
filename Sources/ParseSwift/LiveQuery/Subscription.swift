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
 Represents an update on a specific object from the `ParseLiveQuery` Server.
 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T: ParseObject> {
    /// The object has been updated, and is now included in the query.
    case entered(T)

    /// The object has been updated, and is no longer included in the query.
    case left(T)

    /// The object has been created, and is a part of the query.
    case created(T)

    /// The object has been updated, and is still a part of the query.
    case updated(T)

    /// The object has been deleted, and is no longer included in the query.
    case deleted(T)

    init?(event: EventResponse<T>) {
        switch event.op {
        case .enter: self = .entered(event.object)
        case .leave: self = .left(event.object)
        case .create: self = .created(event.object)
        case .update: self = .updated(event.object)
        case .delete: self = .deleted(event.object)
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
 A default implementation of the `ParseSubscription` protocol. Suitable for `ObjectObserved`
 as the subscription can be used as a SwiftUI publisher. Meaning it can serve
 indepedently as a ViewModel in MVVM.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
open class Subscription<T: ParseObject>: ParseSubscription, ObservableObject {
    //The query subscribed to.
    public var query: Query<T>
    //The ParseObject
    public typealias Object = T

    /// Notifies there's a new event related to a specific query.
    private (set) var event: (query: Query<T>, event: Event<T>)? {
        willSet {
            if newValue != nil {
                subscribed = nil
                unsubscribed = nil
                objectWillChange.send()
            }
        }
    }

    /// Notifies when a subscription request has been fulfilled and if it is new.
    private (set) var subscribed: (query: Query<T>, isNew: Bool)? {
        willSet {
            if newValue != nil {
                unsubscribed = nil
                event = nil
                objectWillChange.send()
            }
        }
    }

    /// Notifies when an unsubscribe request has been fulfilled.
    private (set) var unsubscribed: Query<T>? {
        willSet {
            if newValue != nil {
                subscribed = nil
                event = nil
                objectWillChange.send()
            }
        }
    }

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public init(query: Query<T>) {
        self.query = query
        self.subscribed = nil
        self.event = nil
        self.unsubscribed = nil
    }

    open func didReceive(_ eventData: Data) throws {
        // Need to decode the event with respect to the `ParseObject`.
        let eventMessage = try ParseCoding.jsonDecoder().decode(EventResponse<T>.self, from: eventData)
        guard let event = Event(event: eventMessage) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: couldn't create event.")
        }
        self.event = (query, event)
    }

    open func didSubscribe(_ new: Bool) {
        self.subscribed = (query, new)
    }

    open func didUnsubscribe() {
        self.unsubscribed = query
    }
}

/**
 A default implementation of the `ParseSubscription` protocol using closures for callbacks.
 */
open class SubscriptionCallback<T: ParseObject>: ParseSubscription {
    //The query subscribed to.
    public var query: Query<T>
    //The ParseObject
    public typealias Object = T
    fileprivate var eventHandlers: [(Query<T>, Event<T>) -> Void] = []
    fileprivate var subscribeHandlers: [(Query<T>, Bool) -> Void] = []
    fileprivate var unsubscribeHandlers: [(Query<T>) -> Void] = []

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public init(query: Query<T>) {
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
     Register a callback for when a client succesfully subscribes to a query.
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

    open func didReceive(_ eventData: Data) throws {
        // Need to decode the event with respect to the `ParseObject`.
        let eventMessage = try ParseCoding.jsonDecoder().decode(EventResponse<T>.self, from: eventData)
        guard let event = Event(event: eventMessage) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: couldn't create event.")
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

extension SubscriptionCallback {

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
}
