//
//  Subscription.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
//

#if canImport(Combine)
import Foundation

/**
 A default implementation of the `QuerySubscribable` protocol. Suitable for `ObjectObserved`
 as the subscription can be used as a SwiftUI publisher. Meaning it can serve
 indepedently as a ViewModel in MVVM. Also can be used as a Combine publisher. See Apple's
 [documentation](https://developer.apple.com/documentation/combine/observableobject)
 for more details.
 */
open class Subscription<T: ParseObject>: QueryViewModel<T>, QuerySubscribable {

    /// Updates and notifies when there is a new event related to a specific query.
    open var event: (query: Query<T>, event: Event<T>)? {
        willSet {
            if newValue != nil {
                subscribed = nil
                unsubscribed = nil
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /// Updates and notifies when a subscription request has been fulfilled and if it is new.
    open var subscribed: (query: Query<T>, isNew: Bool)? {
        willSet {
            if newValue != nil {
                unsubscribed = nil
                event = nil
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /// Updates and notifies when an unsubscribe request has been fulfilled.
    open var unsubscribed: Query<T>? {
        willSet {
            if newValue != nil {
                subscribed = nil
                event = nil
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public required init(query: Query<T>) {
        super.init(query: query)
        self.subscribed = nil
        self.event = nil
        self.unsubscribed = nil
    }

    // MARK: QuerySubscribable

    open func didReceive(_ eventData: Data) throws {
        // Need to decode the event with respect to the `ParseObject`.
        let eventMessage = try ParseCoding.jsonDecoder().decode(EventResponse<T>.self, from: eventData)
        guard let event = Event(event: eventMessage) else {
            throw ParseError(code: .unknownError, message: "ParseLiveQuery Error: Could not create event.")
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

#endif
