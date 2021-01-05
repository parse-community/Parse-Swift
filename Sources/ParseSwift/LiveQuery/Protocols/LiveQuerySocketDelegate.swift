//
//  LiveQuerySocketDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
protocol LiveQuerySocketDelegate: AnyObject {
    func status(_ status: LiveQuerySocketStatus)
    func receivedError(_ error: ParseError)
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?)
    func receivedChallenge(challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func received(_ data: Data)
    #if !os(watchOS)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
    #endif
}
