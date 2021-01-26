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

#if !os(Linux)
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

    /// Updates and notifies when there's a new event related to a specific query.
    public internal(set) var event: (query: Query<T>, event: Event<T>)? {
        willSet {
            if newValue != nil {
                subscribed = nil
                unsubscribed = nil
                objectWillChange.send()
            }
        }
    }

    /// Updates and notifies when a subscription request has been fulfilled and if it is new.
    public internal(set) var subscribed: (query: Query<T>, isNew: Bool)? {
        willSet {
            if newValue != nil {
                unsubscribed = nil
                event = nil
                objectWillChange.send()
            }
        }
    }

    /// Updates and notifies when an unsubscribe request has been fulfilled.
    public internal(set) var unsubscribed: Query<T>? {
        willSet {
            if newValue != nil {
                subscribed = nil
                event = nil
                objectWillChange.send()
            }
        }
    }

    /// The objects found in a `find`, `first`, or `aggregate`
    /// query.
    /// - note: this will only countain one item for `first`.
    public internal(set) var results: [T]? {
        willSet {
            if newValue != nil {
                resultsCodable = nil
                count = nil
                error = nil
                objectWillChange.send()
            }
        }
    }

    /// The number of items found in a `count` query.
    public internal(set) var count: Int? {
        willSet {
            if newValue != nil {
                results = nil
                resultsCodable = nil
                error = nil
                objectWillChange.send()
            }
        }
    }

    /// Results of a `explain` or `hint` query.
    public internal(set) var resultsCodable: AnyCodable? {
        willSet {
            if newValue != nil {
                results = nil
                count = nil
                error = nil
                objectWillChange.send()
            }
        }
    }

    /// If an error occured during a `find`, `first`, `count`, or `aggregate`
    /// query.
    public internal(set) var error: ParseError? {
        willSet {
            if newValue != nil {
                count = nil
                results = nil
                resultsCodable = nil
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

    /**
      Finds objects and publishes them as `results` afterwards.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
    */
    open func find(options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.find(options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.results = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Finds objects and publishes them as `resultsCodable` afterwards.

      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
    */
    open func find(explain: Bool, hint: String? = nil, options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.find(explain: explain, hint: hint, options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.resultsCodable = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Gets an object and publishes them as `results` afterwards.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
    */
    open func first(options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.first(options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.results = [results]
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Gets an object and publishes them as `resultsCodable` afterwards.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
    */
    open func first(explain: Bool, hint: String? = nil, options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.first(explain: explain, hint: hint, options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.resultsCodable = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Counts objects and publishes them as `count` afterwards.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
    */
    open func count(options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.count(options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.count = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Counts objects and publishes them as `resultsCodable` afterwards.
      - parameter explain: Used to toggle the information on the query plan.
      - parameter hint: String or Object of index that should be used when executing query.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
    */
    open func count(explain: Bool, hint: String? = nil, options: API.Options = [], callbackQueue: DispatchQueue = .main) {
        query.count(explain: explain, hint: hint, options: options) { result in
            switch result {

            case .success(let results):
                self.resultsCodable = results
            case .failure(let error):
                self.error = error
            }
        }
    }

    /**
      Executes an aggregate query and publishes the results as `results` afterwards.
        - requires: `.useMasterKey` has to be available and passed as one of the set of `options`.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - warning: This hasn't been tested thoroughly.
    */
    open func aggregate(_ pipeline: Query<T>.AggregateType,
                        options: API.Options = [],
                        callbackQueue: DispatchQueue = .main) {
        query.aggregate(pipeline, options: options, callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let results):
                self.results = results
            case .failure(let error):
                self.error = error
            }
        }
    }
}
#endif

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
