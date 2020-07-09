//
//  API+Commands.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

internal extension API {
    struct Command<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: ((Data) throws -> U)
        let params: [String: String?]?

        internal var data: Data? {
            return try? getJSONEncoder().encode(body)
        }

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             mapper: @escaping ((Data) throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.mapper = mapper
            self.params = params
        }

        public func execute(options: API.Options) throws -> U {
            let params = self.params?.getQueryItems()
            let headers = API.getHeaders(options: options)
            let url = ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent)

            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = params

            var urlRequest = URLRequest(url: components.url!)
            urlRequest.allHTTPHeaderFields = headers
            if let body = data {
                urlRequest.httpBody = body
            }
            urlRequest.httpMethod = method.rawValue
            let responseData = try URLSession.shared.syncDataTask(with: urlRequest)
            do {
                return try mapper(responseData)
            } catch _ {
                throw try getDecoder().decode(ParseError.self, from: responseData)
            }
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}

internal extension API.Command {
    // MARK: Saving
    static func saveCommand<T>(_ object: T) -> API.Command<T, T> where T: ObjectType {
        if object.isSaved {
            return updateCommand(object)
        }
        return createCommand(object)
    }

    // MARK: Saving - private
    private static func createCommand<T>(_ object: T) -> API.Command<T, T> where T: ObjectType {
        let mapper = { (data) -> T in
            try getDecoder().decode(SaveResponse.self, from: data).apply(object)
        }
        return API.Command<T, T>(method: .POST,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    private static func updateCommand<T>(_ object: T) -> API.Command<T, T> where T: ObjectType {
        let mapper = { (data: Data) -> T in
            try getDecoder().decode(UpdateResponse.self, from: data).apply(object)
        }
        return API.Command<T, T>(method: .PUT,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Fetching
    static func fetchCommand<T>(_ object: T) throws -> API.Command<T, T> where T: ObjectType {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Fetch an object without id")
        }
        return API.Command<T, T>(method: .GET,
                                 path: object.endpoint) { (data) -> T in
                                    try getDecoder().decode(T.self, from: data)
        }
    }
}

extension API.Command where T: ObjectType {

    internal var data: Data? {
        guard let body = body else { return nil }
        return try? body.getEncoder().encode(body)
    }

    static func batch(commands: [API.Command<T, T>]) -> RESTBatchCommandType<T> {
        let commands = commands.compactMap { (command) -> API.Command<T, T>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return API.Command<T, T>(method: command.method, path: .any(path),
                                     body: body, mapper: command.mapper)
        }
        let bodies = commands.compactMap { (command) -> T? in
            return command.body
        }
        let mapper = { (data: Data) -> [(T, ParseError?)] in
            let decodingType = [BatchResponseItem<SaveOrUpdateResponse>].self
            let responses = try getDecoder().decode(decodingType, from: data)
            return bodies.enumerated().map({ (object) -> (T, ParseError?) in
                let response = responses[object.0]
                if let success = response.success {
                    return (success.apply(object.1), nil)
                } else {
                    return (object.1, response.error)
                }
            })
        }
        let batchCommand = BatchCommand(requests: commands)
        return RESTBatchCommandType<T>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}
