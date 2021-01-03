//
//  LiveQueryOperations.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

protocol LiveQueryable: Encodable {}

struct LiveQuery {

    enum Operation: String, Encodable {
        case connect, subscribe, create, enter, update, leave, delete, unsubscribe
    }

    enum OperationResponses: String {
        case connected, subscribed, unsubscribed
    }
}
