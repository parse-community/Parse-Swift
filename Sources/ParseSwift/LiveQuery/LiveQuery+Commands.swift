//
//  LiveQuery+Commands.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

extension LiveQuery {
    struct Command<T, U> where T: Encodable {
        
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

        typealias ReturnType = U // swiftlint:disable:this nesting
        let data: Data
        let mapper: ((Data) throws -> U)
        
        init(data: Data,
            mapper: @escaping ((Data) throws -> U)) {
            self.data = data
            self.mapper = mapper
        }
        
        func executeAsync(callbackQueue: DispatchQueue?,
                          completion: @escaping(Result<U, ParseError>) -> Void) {
        }
    }
}

extension LiveQuery.Command {
    static func connect() throws -> LiveQuery.Command<NoBody, Bool> {
        let encoded = try ParseCoding.jsonEncoder().encode(StandardMessage(operation: .connect, addStandardKeys: true))
        return LiveQuery.Command(data: encoded) { (data) -> Bool in
            let response = try ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data)
            guard let responseOperation = LiveQuery.OperationResponses(rawValue: response.op),
                  responseOperation == .connected else {
                return false
            }
            return true
        }
    }
    
    // MARK: Uploading File - private
    private static func createFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .POST,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    static func subscribe<T: ParseObject>(_ query: Query<T>, requestId: Int) throws -> Data {
        var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
        message.query = query
        message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
        return try ParseCoding.jsonEncoder().encode(message)
    }

    static func update<T: ParseObject>(_ query: Query<T>, requestId: Int) throws -> Data {
        var message = ParseMessage<T>(operation: .subscribe, requestId: requestId)
        message.query = query
        message.sessionToken = BaseParseUser.currentUserContainer?.sessionToken
        return try ParseCoding.jsonEncoder().encode(message)
    }

    static func unsubscribe(_ requestId: Int) throws -> Data {
        try ParseCoding.jsonEncoder().encode(StandardMessage(operation: .unsubscribe, requestId: requestId))
    }
}


