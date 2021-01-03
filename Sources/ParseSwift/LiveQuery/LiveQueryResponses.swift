//
//  LiveQueryResponses.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

struct ConnectionResponse: Decodable {
    let op: String
}

struct UnsubscribedResponse: Decodable {
    let op: String
    let requestId: Int
}

struct ErrorResponse: Decodable {
    let op: String
    let code: Int
    let error: String
    let reconnect: Bool
}
