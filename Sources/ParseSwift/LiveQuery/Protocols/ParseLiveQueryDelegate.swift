//
//  ParseLiveQueryDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

///Receive/respond to notifications from the ParseLiveQuery Server.
public protocol ParseLiveQueryDelegate: AnyObject {

    /**
     Respond to authentication requests from a ParseLiveQuery server. If you become a delegate
     you must implement this method and at at least respond with
     `completionHandler(.performDefaultHandling, nil)` to accept all connections approved
     by the OS. Becoming a delegate allows you to make authentication decisions for all connections in
     the ParseLiveQuery session, meaning there can only be one delegate for the whole session. The newest
     instance to become the delegate will be the only one to receive authentication challenges.
     - parameter challenge: An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call. Its parameters are:
       - disposition - One of several constants that describes how the challenge should be handled.
       - credential - The credential that should be used for authentication if disposition is
     URLSessionAuthChallengeUseCredential; otherwise, `nil`.
     
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
     */
    func receivedChallenge(_ challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                         URLCredential?) -> Void)
    #if !os(watchOS)
    /**
    Receive metrics about the ParseLiveQuery task/connection.
     - parameter metrics: An object that encapsualtes the performance metrics collected by the URL
     Loading System during the execution of a session task.
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics) for more for details.
     */
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
    #endif
}

extension ParseLiveQueryDelegate {
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) { }
}
