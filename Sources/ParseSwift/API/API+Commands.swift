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
        let uploadData: Data?
        let uploadFile: URL?
        let stream: InputStream?

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             uploadData: Data? = nil,
             uploadFile: URL? = nil,
             stream: InputStream? = nil,
             mapper: @escaping ((Data) throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.uploadData = uploadData
            self.uploadFile = uploadFile
            self.stream = stream
            self.mapper = mapper
            self.params = params
        }

        func executeStream(options: API.Options,
                           childObjects: [NSDictionary: PointerType]? = nil,
                           progress: ((Int64, Int64, Int64) -> Void)? = nil,
                           stream: InputStream? = nil) throws {
            if let stream = stream {
                let delegate = ParseURLSessionDelegate(progress: progress, stream: stream)
                let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

                switch self.prepareURLRequest(options: options, childObjects: childObjects) {

                case .success(let urlRequest):
                    if method == .POST || method == .PUT {
                        session.uploadTask(withStreamedRequest: urlRequest).resume()
                        return
                    }
                case .failure(let error):
                    throw error
                }
            }
        }

        func execute(options: API.Options,
                     childObjects: [NSDictionary: PointerType]? = nil,
                     progress: ((Int64, Int64, Int64) -> Void)? = nil) throws -> U {
            var responseResult: Result<U, ParseError>?
            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options,
                              callbackQueue: nil,
                              childObjects: childObjects,
                              progress: progress) { result in
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

        // swiftlint:disable:next function_body_length cyclomatic_complexity
        func executeAsync(options: API.Options, callbackQueue: DispatchQueue?,
                          childObjects: [NSDictionary: PointerType]? = nil,
                          progress: ((Int64, Int64, Int64) -> Void)? = nil,
                          completion: @escaping(Result<U, ParseError>) -> Void) {

            switch self.prepareURLRequest(options: options, childObjects: childObjects) {

            case .success(let urlRequest):
                if path.urlComponent.contains("/files/") {
                    let delegate = ParseURLSessionDelegate(progress: progress)
                    let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                    if method == .POST || method == .PUT {
                        session.uploadTask(with: urlRequest,
                                           from: uploadData,
                                           from: uploadFile,
                                           mapper: mapper) { result in
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
                    } else {
                        session.downloadTask(with: urlRequest, mapper: mapper) { result in
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
                } else {
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
            case .failure(let error):
                completion(.failure(error))
            }
        }

        func prepareURLRequest(options: API.Options,
                               childObjects: [NSDictionary: PointerType]? = nil) -> Result<URLRequest, ParseError> {
            let params = self.params?.getQueryItems()
            let headers = API.getHeaders(options: options)
            let url = ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent)

            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return .failure(ParseError(code: .unknownError,
                                           message: "couldn't unrwrap url components for \(url)"))
            }
            components.queryItems = params

            guard let urlComponents = components.url else {
                return .failure(ParseError(code: .unknownError,
                                           message: "couldn't create url from components for \(components)"))
            }

            var urlRequest = URLRequest(url: urlComponents)
            urlRequest.allHTTPHeaderFields = headers
            if let urlBody = body {
                if let childObjects = childObjects {
                    guard let bodyData = try? ParseCoding
                            .parseEncoder()
                            .encode(urlBody, collectChildren: false,
                                    objectsSavedBeforeThisOne: childObjects) else {
                            return .failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)"))
                    }
                    urlRequest.httpBody = bodyData.encoded
                } else {
                    guard let bodyData = try? ParseCoding
                            .parseEncoder()
                            .encode(urlBody) else {
                            return .failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)"))
                    }
                    urlRequest.httpBody = bodyData
                }
            }
            urlRequest.httpMethod = method.rawValue

            return .success(urlRequest)
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}

internal extension API.Command {
    // MARK: Uploading
    static func uploadFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        if object.isSaved {
            return updateFileCommand(object)
        }
        return createFileCommand(object)
    }

    // MARK: Uploading - private
    private static func createFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .POST,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    private static func updateFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .PUT,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    // MARK: Downloading File
    static func downloadFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .GET,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    // MARK: Deleting File
    static func deleteFileCommand(_ object: ParseFile) -> API.Command<ParseFile, NoBody> {
        API.Command(method: .DELETE,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }

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
            try ParseCoding.jsonDecoder().decode(T.self, from: data)
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

    static func batch(commands: [API.Command<NoBody, NoBody>]) -> RESTBatchCommandNoBodyType<Bool> {
        let commands = commands.compactMap { (command) -> API.Command<NoBody, NoBody>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
            return API.Command<NoBody, NoBody>(
                method: command.method,
                path: .any(path), mapper: command.mapper)
        }

        let mapper = { (data: Data) -> [Result<Bool, ParseError>] in

            let decodingType = [BatchResponseItem<NoBody>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return responses.enumerated().map({ (object) -> (Result<Bool, ParseError>) in
                    let response = responses[object.offset]
                    if response.success != nil {
                        return .success(true)
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
        return RESTBatchCommandNoBodyType<Bool>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
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
} // swiftlint:disable:this file_length
