//
//  API+Commands.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

internal extension API {
    struct Command<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U // swiftlint:disable:this nesting
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
            var response: Result<U, ParseError>?

            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options, callbackQueue: nil) { result in
                response = result
                group.leave()
            }
            group.wait()

            guard let responseData = response else {
                throw ParseError(code: .unknownError,
                                 message: "couldn't unrwrap server response")
            }
            return try responseData.get()
        }

        public func executeAsync(options: API.Options, callbackQueue: DispatchQueue?,
                                 completion: @escaping(Result<U, ParseError>) -> Void) {
            let params = self.params?.getQueryItems()
            let headers = API.getHeaders(options: options)
            let url = ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent)

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let urlComponents = components.url else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: "couldn't unrwrap url components for \(url)")))
                return
            }
            components.queryItems = params

            var urlRequest = URLRequest(url: urlComponents)
            urlRequest.allHTTPHeaderFields = headers
            if let body = data {
                urlRequest.httpBody = body
            }
            urlRequest.httpMethod = method.rawValue

            URLSession.shared.dataTask(with: urlRequest, callbackQueue: callbackQueue) { result in
                switch result {

                case .success(let responseData):
                    guard let decoded = try? self.mapper(responseData) else {
                        guard let parseError = try? getDecoder().decode(ParseError.self, from: responseData) else {
                            completion(.failure(ParseError(code: .unknownError, message: "cannot decode error")))
                            return
                        }
                        completion(.failure(parseError))
                        return
                    }
                    completion(.success(decoded))

                case .failure(let error):
                    completion(.failure(error))
                }
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
        let mapper = { (data: Data) -> [Result<T, ParseError>] in
            let decodingType = [BatchResponseItem<SaveOrUpdateResponse>].self
            do {
                let responses = try getDecoder().decode(decodingType, from: data)
                return bodies.enumerated().map({ (object) -> (Result<T, ParseError>) in
                    let response = responses[object.0]
                    if let success = response.success {
                        return .success(success.apply(object.1))
                    } else {
                        guard let parseError = response.error else {
                            return .failure(ParseError(code: .unknownError, message: "unknown error"))
                        }

                        return .failure(parseError)
                    }
                })
            } catch {
                guard let parseError = error as? ParseError else {
                    return [(.failure(ParseError(code: .unknownError, message: "decoding error: \(error)")))]
                }
                return [(.failure(parseError))]
            }
        }
        let batchCommand = BatchCommand(requests: commands)
        return RESTBatchCommandType<T>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}
