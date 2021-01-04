//
//  ParseLiveQueryDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

public protocol ParseLiveQueryDelegate: AnyObject {
    func receivedChallenge(_ challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                         URLCredential?) -> Void)
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics)
}

extension ParseLiveQueryDelegate {
    func receivedMetrics(_ metrics: URLSessionTaskTransactionMetrics) { }
}
