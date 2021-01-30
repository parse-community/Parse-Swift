//
//  LiveQuerySocketDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
protocol LiveQuerySocketDelegate: AnyObject {
    func status(_ status: LiveQuerySocket.Status)
    func close(useDedicatedQueue: Bool)
    func receivedError(_ error: ParseError)
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?)
    func received(challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func received(_ data: Data)
    #if !os(watchOS)
    func received(_ metrics: URLSessionTaskTransactionMetrics)
    #endif
}
#endif
