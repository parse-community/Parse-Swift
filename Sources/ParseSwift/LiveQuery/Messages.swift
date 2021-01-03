//
//  Messages.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

struct StandardMessage: LiveQueryable {
    var op: Operation
    var applicationId: String?
    var clientKey: String?
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?
    
    init(operation: Operation, addStandardKeys: Bool = false) {
        self.op = operation
        if addStandardKeys {
            self.applicationId = ParseConfiguration.applicationId
            self.clientKey = ParseConfiguration.clientKey
            self.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
            self.installationId = BaseParseInstallation.currentInstallationContainer.installationId
        }
    }
    
    init(operation: Operation, requestId: Int) {
        self.init(operation: operation)
        self.requestId = requestId
    }
}

struct ParseMessage<T: ParseObject>: LiveQueryable {
    var op: Operation
    var applicationId: String?
    var clientKey: String?
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?
    var query: Query<T>?
    
    init(operation: Operation, requestId: Int, addStandardKeys: Bool = false) {
        self.op = operation
        if addStandardKeys {
            self.applicationId = ParseConfiguration.applicationId
            self.clientKey = ParseConfiguration.clientKey
            self.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
            self.installationId = BaseParseInstallation.currentInstallationContainer.installationId
        }
    }
}


struct ConnectionResponse: Decodable {
    let op: OperationResponses
}

struct UnsubscribedResponse: Decodable {
    let op: OperationResponses
    let requestId: Int
}

struct ErrorResponse: Decodable {
    let op: OperationResponses
    let code: Int
    let error: String
    let reconnect: Bool
}
