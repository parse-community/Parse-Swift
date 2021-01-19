//
//  ParseSubscription.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 This protocol describes the interface for handling events from a `ParseLiveQuery` client.
 You can use this protocol on any custom class of yours, instead of Subscription, if it fits your use case better.
 */
public protocol  ParseSubscription: AnyObject {
    /// The type of the `ParseObject` that this handler uses.
    associatedtype Object: ParseObject

    var query: Query<Object> {get set}

    /**
     Tells the handler that an event has been received from the `ParseLiveQuery` Server.
     - parameter eventData: The event data that has been recieved from the server.
     */
    func didReceive(_ eventData: Data) throws

    /**
     Tells the handler that a query has been successfully registered with the server.
     - note: This may be invoked multiple times if the client disconnects/reconnects.
     */
    func didSubscribe(_ new: Bool)

    /**
     Tells the handler that a query has been successfully deregistered from the server.
     - note: This is not called unless `unsubscribe()` is explicitly called.
     */
    func didUnsubscribe()
}
