//
//  API+Commands.swift
//  ParseSwift (iOS)
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {

    struct Command<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: ((Data) throws -> U)
        let params: [String: String?]?

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

        func execute(options: API.Options, childObjects: [NSDictionary: PointerType]? = nil) throws -> U {
            var responseResult: Result<U, ParseError>?

            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options, callbackQueue: nil, childObjects: childObjects) { result in
                responseResult = result
                group.leave()
            }
            group.wait()

            guard let response = responseResult else {
                throw ParseError(code: .unknownError,
                                 message: "couldn't unrwrap server response")
            }
            return try response.get()
        }

        // swiftlint:disable:next function_body_length
        func executeAsync(options: API.Options, callbackQueue: DispatchQueue?,
                          childObjects: [NSDictionary: PointerType]? = nil,
                          completion: @escaping(Result<U, ParseError>) -> Void) {
            let params = self.params?.getQueryItems()
            let headers = API.getHeaders(options: options)
            let url = ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent)

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: "couldn't unrwrap url components for \(url)")))
                return
            }
            components.queryItems = params

            guard let urlComponents = components.url else {
                completion(.failure(ParseError(code: .unknownError,
                                               message: "couldn't create url from components for \(components)")))
                return
            }

            var urlRequest = URLRequest(url: urlComponents)
            urlRequest.allHTTPHeaderFields = headers
            if let urlBody = body {
                if let childObjects = childObjects {
                    guard let bodyData = try? ParseCoding
                            .parseEncoder()
                            .encode(urlBody, collectChildren: false,
                                    objectsSavedBeforeThisOne: childObjects) else {
                        completion(.failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)")))
                        return
                    }
                    urlRequest.httpBody = bodyData.encoded
                } else {
                    guard let bodyData = try? ParseCoding.parseEncoder().encode(urlBody) else {
                        completion(.failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)")))
                        return
                    }
                    urlRequest.httpBody = bodyData
                }
            }
            urlRequest.httpMethod = method.rawValue

            URLSession.shared.dataTask(with: urlRequest, mapper: mapper) { result in
                switch result {

                case .success(let decoded):
                    if let callbackQueue = callbackQueue {
                        callbackQueue.async { completion(.success(decoded)) }
                    } else {
                        completion(.success(decoded))
                    }

                case .failure(let error):
                    if let callbackQueue = callbackQueue {
                        callbackQueue.async { completion(.failure(error)) }
                    } else {
                        completion(.failure(error))
                    }
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
    static func saveCommand<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        if object.isSaved {
            return updateCommand(object)
        }
        return createCommand(object)
    }

    // MARK: Saving - private
    private static func createCommand<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        let mapper = { (data) -> T in
            try ParseCoding.jsonDecoder().decode(SaveResponse.self, from: data).apply(to: object)
        }
        return API.Command<T, T>(method: .POST,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    private static func updateCommand<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        let mapper = { (data: Data) -> T in
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: data).apply(to: object)
        }
        return API.Command<T, T>(method: .PUT,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Saving Encodable
    static func saveCommand<T>(_ object: T) throws -> API.Command<T, PointerType> where T: Encodable {
        guard let objectable = object as? Objectable else {
            throw ParseError(code: .unknownError, message: "Not able to cast to objectable. Not saving")
        }
        if objectable.isSaved {
            return try updateCommand(object)
        } else {
            return try createCommand(object)
        }
    }

    // MARK: Saving Encodable - private
    private static func createCommand<T>(_ object: T) throws -> API.Command<T, PointerType> where T: Encodable {
        guard var objectable = object as? Objectable else {
            throw ParseError(code: .unknownError, message: "Not able to cast to objectable. Not saving")
        }
        let mapper = { (data: Data) -> PointerType in
            let baseObjectable = try ParseCoding.jsonDecoder().decode(BaseObjectable.self, from: data)
            objectable.objectId = baseObjectable.objectId
            return objectable.toPointer()
        }
        return API.Command<T, PointerType>(method: .POST,
                                 path: objectable.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    private static func updateCommand<T>(_ object: T) throws -> API.Command<T, PointerType> where T: Encodable {
        guard var objectable = object as? Objectable else {
            throw ParseError(code: .unknownError, message: "Not able to cast to objectable. Not saving")
        }
        let mapper = { (data: Data) -> PointerType in
            let baseObjectable = try ParseCoding.jsonDecoder().decode(BaseObjectable.self, from: data)
            objectable.objectId = baseObjectable.objectId
            return objectable.toPointer()
        }
        return API.Command<T, PointerType>(method: .PUT,
                                 path: objectable.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Fetching
    static func fetchCommand<T>(_ object: T) throws -> API.Command<T, T> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Fetch an object without id")
        }

        return API.Command<T, T>(
            method: .GET,
            path: object.endpoint
        ) { (data) -> T in
            try ParseCoding.jsonDecoder().decode(FetchResponse.self, from: data).apply(to: object)
        }
    }

    // MARK: Deleting
    static func deleteCommand<T>(_ object: T) throws -> API.Command<NoBody, NoBody> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.Command<NoBody, NoBody>(
            method: .DELETE,
            path: object.endpoint
        ) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }
}

extension API.Command where T: ParseObject {

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
        let bodies = commands.compactMap { (command) -> (body: T, command: API.Method)?  in
            guard let body = command.body else {
                return nil
            }
            return (body: body, command: command.method)
        }
        let mapper = { (data: Data) -> [Result<T, ParseError>] in
            let decodingType = [BatchResponseItem<WriteResponse>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return bodies.enumerated().map({ (object) -> (Result<T, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success {
                        return .success(success.apply(to: object.element.body, method: object.element.command))
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

extension API.Command where T: Encodable {

    internal var data: Data? {
        guard let body = body else { return nil }
        return try? ParseCoding.parseEncoder().encode(body)
    }

    static func batch(commands: [API.Command<T, PointerType>]) -> RESTBatchCommandTypeEncodable<T> {
        let commands = commands.compactMap { (command) -> API.Command<T, PointerType>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return API.Command<T, PointerType>(method: command.method, path: .any(path),
                                     body: body, mapper: command.mapper)
        }
        let bodies = commands.compactMap { (command) -> (body: T, command: API.Method)?  in
            guard let body = command.body else {
                return nil
            }
            return (body: body, command: command.method)
        }
        let mapper = { (data: Data) -> [Result<PointerType, ParseError>] in
            let decodingType = [BatchResponseItem<PointerSaveResponse>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return bodies.enumerated().map({ (object) -> (Result<PointerType, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success {
                        guard let successfulResponse = try? success.apply(to: object.element.body) else {
                            return.failure(ParseError(code: .unknownError, message: "unknown error"))
                        }
                        return .success(successfulResponse)
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
        return RESTBatchCommandTypeEncodable<T>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}
