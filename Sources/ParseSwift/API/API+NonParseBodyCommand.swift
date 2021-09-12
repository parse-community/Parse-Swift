//
//  API+NonParseBodyCommand.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/12/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {
    // MARK: API.NonParseBodyCommand
    struct NonParseBodyCommand<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: ((Data) throws -> U)

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             mapper: @escaping ((Data) throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.mapper = mapper
        }

        func execute(options: API.Options) throws -> U {
            var responseResult: Result<U, ParseError>?
            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options) { result in
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

        // MARK: Asynchronous Execution
        func executeAsync(options: API.Options,
                          completion: @escaping(Result<U, ParseError>) -> Void) {

            switch self.prepareURLRequest(options: options) {
            case .success(let urlRequest):
                URLSession.parse.dataTask(with: urlRequest, mapper: mapper) { result in
                    switch result {

                    case .success(let decoded):
                        completion(.success(decoded))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        // MARK: URL Preperation
        func prepareURLRequest(options: API.Options) -> Result<URLRequest, ParseError> {
            var headers = API.getHeaders(options: options)
            if !(method == .POST) && !(method == .PUT) && !(method == .PATCH) {
                headers.removeValue(forKey: "X-Parse-Request-Id")
            }
            let url = ParseSwift.configuration.serverURL.appendingPathComponent(path.urlComponent)

            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let urlComponents = components.url else {
                return .failure(ParseError(code: .unknownError,
                                           message: "couldn't unrwrap url components for \(url)"))
            }

            var urlRequest = URLRequest(url: urlComponents)
            urlRequest.allHTTPHeaderFields = headers
            if let urlBody = body {
                guard let bodyData = try? ParseCoding.jsonEncoder().encode(urlBody) else {
                    return .failure(ParseError(code: .unknownError,
                                                   message: "couldn't encode body \(urlBody)"))
                }
                urlRequest.httpBody = bodyData
            }
            urlRequest.httpMethod = method.rawValue
            urlRequest.cachePolicy = requestCachePolicy(options: options)
            return .success(urlRequest)
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}

internal extension API.NonParseBodyCommand {

    // MARK: Deleting
    static func delete<T>(_ object: T) throws -> API.NonParseBodyCommand<NoBody, NoBody> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError,
                             message: "Cannot delete an object without an objectId")
        }

        let mapper = { (data: Data) -> NoBody in
            if let error = try? ParseCoding
                .jsonDecoder()
                .decode(ParseError.self,
                        from: data) {
                throw error
            } else {
                return NoBody()
            }
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(method: .DELETE,
                                                       path: object.endpoint,
                                                       mapper: mapper)
    }
}

internal extension API.NonParseBodyCommand {
    // MARK: Batch - Child Objects
    static func batch(objects: [ParseType],
                      transaction: Bool) throws -> RESTBatchCommandTypeEncodable<AnyCodable> {
        let batchCommands = try objects.compactMap { (object) -> API.BatchCommand<AnyCodable, PointerType>? in
            guard var objectable = object as? Objectable else {
                return nil
            }
            let method: API.Method!
            if objectable.isSaved {
                method = .PUT
            } else {
                method = .POST
            }

            let mapper = { (baseObjectable: BaseObjectable) throws -> PointerType in
                objectable.objectId = baseObjectable.objectId
                return try objectable.toPointer()
            }

            let path = ParseSwift.configuration.mountPath + objectable.endpoint.urlComponent
            let encoded = try ParseCoding.parseEncoder().encode(object)
            let body = try ParseCoding.jsonDecoder().decode(AnyCodable.self, from: encoded)
            return API.BatchCommand<AnyCodable, PointerType>(method: method,
                                                             path: .any(path),
                                                             body: body,
                                                             mapper: mapper)
        }

        let mapper = { (data: Data) -> [Result<PointerType, ParseError>] in
            let decodingType = [BatchResponseItem<BaseObjectable>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return batchCommands.enumerated().map({ (object) -> (Result<PointerType, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success {
                        guard let successfulResponse = try? object.element.mapper(success) else {
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
        let batchCommand = BatchChildCommand(requests: batchCommands,
                                              transaction: transaction)
        return RESTBatchCommandTypeEncodable<AnyCodable>(method: .POST,
                                                         path: .batch,
                                                         body: batchCommand,
                                                         mapper: mapper)
    }
}
