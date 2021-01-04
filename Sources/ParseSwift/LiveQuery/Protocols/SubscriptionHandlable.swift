//
//   SubscriptionHandlable.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 This protocol describes the interface for handling events from a liveQuery client.
 You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
 */
public protocol  SubscriptionHandlable: AnyObject {
    /// The type of the `ParseObject` subclass that this handler uses.
    associatedtype SubscribedObject: ParseObject

    var query: Query<SubscribedObject> {get set}
    /**
     Tells the handler that an event has been received from the live query server.
     - parameter event: The event that has been recieved from the server.
     - parameter query: The query that the event occurred on.
     - parameter client: The live query client which received this event.
     */
    func didReceive(_ event: Event<SubscribedObject>, forQuery query: Query<SubscribedObject>)

    /**
     Tells the handler that an error has been received from the live query server.
     - parameter error: The error that the server has encountered.
     - parameter query: The query that the error occurred on.
     - parameter client: The live query client which received this error.
     */
    func didEncounter(_ error: Error, forQuery query: Query<SubscribedObject>)

    /**
     Tells the handler that a query has been successfully registered with the server.
     - note: This may be invoked multiple times if the client disconnects/reconnects.
     - parameter query: The query that has been subscribed.
     - parameter client: The live query client which subscribed this query.
     */
    func didSubscribe(toQuery query: Query<SubscribedObject>)

    /**
     Tells the handler that a query has been successfully deregistered from the server.
     - note: This is not called unless `unregister()` is explicitly called.
     - parameter query: The query that has been unsubscribed.
     - parameter client: The live query client which unsubscribed this query.
     */
    func didUnsubscribe(fromQuery query: Query<SubscribedObject>)
}
