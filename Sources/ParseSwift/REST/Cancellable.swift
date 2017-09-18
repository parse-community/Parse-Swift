//
//  Cancellable.swift
//  ParseSwift (iOS)
//
//  Created by Pranjal Satija on 9/10/17.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

public protocol Cancellable {
    func cancel()
}

extension URLSessionTask: Cancellable { }
