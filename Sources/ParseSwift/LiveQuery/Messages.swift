//
//  Messages.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

struct StandardMessage: LiveQueryable, Encodable {
    var op: Operation // swiftlint:disable:this identifier_name
    var applicationId: String?
    var clientKey: String?
    var masterKey: String? // swiftlint:disable:this inclusive_language
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?

    init(operation: Operation, addStandardKeys: Bool = false) {
        self.op = operation
        if addStandardKeys {
            self.applicationId = ParseConfiguration.applicationId
            self.masterKey = ParseConfiguration.masterKey
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

struct ParseMessage<T: ParseObject>: LiveQueryable, Encodable {
    var op: Operation // swiftlint:disable:this identifier_name
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

struct ConnectionResponse: LiveQueryable, Decodable {
    let op: OperationResponses // swiftlint:disable:this identifier_name
}

struct UnsubscribedResponse: LiveQueryable, Decodable {
    let op: OperationResponses // swiftlint:disable:this identifier_name
    let requestId: Int
}

struct ErrorResponse: LiveQueryable, Decodable {
    let op: OperationResponses // swiftlint:disable:this identifier_name
    let code: Int
    let error: String
    let reconnect: Bool
}

struct PreliminaryMessageResponse: LiveQueryable, Decodable {
    let op: OperationResponses // swiftlint:disable:this identifier_name
    let code: Int
}
