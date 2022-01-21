//
//  ParseLiveQueryDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

/// Receive/respond to notifications from the ParseLiveQuery Server.
public protocol ParseLiveQueryDelegate: AnyObject {

    /**
     Respond to authentication requests from a ParseLiveQuery Server. If you become a delegate
     and implement this method you will need to with
     `completionHandler(.performDefaultHandling, nil)` to accept all connections approved
     by the OS. Becoming a delegate allows you to make authentication decisions for all connections in
     the `ParseLiveQuery` session, meaning there can only be one delegate for the whole session. The newest
     instance to become the delegate will be the only one to receive authentication challenges.
     - parameter challenge: An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call. Its parameters are:
       - disposition - One of several constants that describes how the challenge should be handled.
       - credential - The credential that should be used for authentication if disposition is
     URLSessionAuthChallengeUseCredential; otherwise, `nil`.
     
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
     */
    func received(_ challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                URLCredential?) -> Void)

    /**
    Receive errors from the ParseLiveQuery task/connection.
     - parameter error: An error from the session task.
     - note: The type of error received can vary from `ParseError`, `URLError`, `POSIXError`, etc.
     */
    func received(_ error: Error)

    /**
    Receive unsupported data from the ParseLiveQuery task/connection.
     - parameter error: An error from the session task.
     */
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?)

    #if !os(watchOS)
    /**
    Receive metrics about the ParseLiveQuery task/connection.
     - parameter metrics: An object that encapsualtes the performance metrics collected by the URL
     Loading System during the execution of a session task.
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics) for more for details.
     */
    func received(_ metrics: URLSessionTaskTransactionMetrics)
    #endif

    /**
    Receive notifications when the ParseLiveQuery closes a task/connection.
     - parameter code: The close code provided by the server.
     - parameter reason: The close reason provided by the server.
     If the close frame didn’t include a reason, this value is nil.
     */
    func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?)
}

public extension ParseLiveQueryDelegate {
    func received(_ challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    func received(_ error: Error) { }
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?) { }
    func received(_ metrics: URLSessionTaskTransactionMetrics) { }
    func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) { }
}
#endif
