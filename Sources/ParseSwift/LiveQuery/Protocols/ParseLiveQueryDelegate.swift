//
//  ParseLiveQueryDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

///Receive/respond to notifications from the ParseLiveQuery Server.
public protocol ParseLiveQueryDelegate: AnyObject {
    /**
     Respond to authentication requests from a ParseLiveQuery server. If you become a delegate
     you must implement this method and at at least respond with
     `completionHandler(.performDefaultHandling, nil)` to accept all connections approved
     by the OS.
     - parameter challenge: An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call. Its parameters are:
       - disposition - One of several constants that describes how the challenge should be handled.
       - credential - The credential that should be used for authentication if disposition is NSURLSessionAuthChallengeUseCredential; otherwise, `nil`.
     
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
     */
    func receivedChallenge(_ challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                         URLCredential?) -> Void)
    
    /**
    Receive metrics about the ParseLiveQuery connection.
     - parameter metrics: An object that encapsualtes the performance metrics collected by the URL Loading System during the execution of a session task.
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics) for more for details.
     */
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
}

extension ParseLiveQueryDelegate {
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) { }
}
