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
    // swiftlint:disable:next type_body_length
    struct Command<T, U>: Encodable where T: Encodable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: ((Data) throws -> U)
        let params: [String: String?]?
        let uploadData: Data?
        let uploadFile: URL?
        let parseURL: URL?
        let otherURL: URL?
        let stream: InputStream?

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             uploadData: Data? = nil,
             uploadFile: URL? = nil,
             parseURL: URL? = nil,
             otherURL: URL? = nil,
             stream: InputStream? = nil,
             mapper: @escaping ((Data) throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.uploadData = uploadData
            self.uploadFile = uploadFile
            self.parseURL = parseURL
            self.otherURL = otherURL
            self.stream = stream
            self.mapper = mapper
            self.params = params
        }

        // MARK: Synchronous Execution
        func executeStream(options: API.Options,
                           childObjects: [NSDictionary: PointerType]? = nil,
                           childFiles: [UUID: ParseFile]? = nil,
                           uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                           stream: InputStream) throws {
            switch self.prepareURLRequest(options: options, childObjects: childObjects, childFiles: childFiles) {

            case .success(let urlRequest):
                if method == .POST || method == .PUT {
                    if !ParseConfiguration.isTestingSDK {
                        let delegate = ParseURLSessionDelegate(callbackQueue: nil,
                                                               uploadProgress: uploadProgress,
                                                               stream: stream)
                        let session = URLSession(configuration: .default,
                                                 delegate: delegate,
                                                 delegateQueue: nil)
                        session.uploadTask(withStreamedRequest: urlRequest).resume()
                    } else {
                        URLSession.testing.uploadTask(withStreamedRequest: urlRequest).resume()
                    }
                    return
                }
            case .failure(let error):
                throw error
            }
        }

        func execute(options: API.Options,
                     childObjects: [NSDictionary: PointerType]? = nil,
                     childFiles: [UUID: ParseFile]? = nil,
                     uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil) throws -> U {
            var responseResult: Result<U, ParseError>?
            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options,
                              callbackQueue: nil,
                              childObjects: childObjects,
                              childFiles: childFiles,
                              uploadProgress: uploadProgress,
                              downloadProgress: downloadProgress) { result in
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
        // swiftlint:disable:next function_body_length cyclomatic_complexity
        func executeAsync(options: API.Options, callbackQueue: DispatchQueue?,
                          childObjects: [NSDictionary: PointerType]? = nil,
                          childFiles: [UUID: ParseFile]? = nil,
                          uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                          downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil,
                          completion: @escaping(Result<U, ParseError>) -> Void) {

            if !path.urlComponent.contains("/files/") {
                //All ParseObjects use the shared URLSession
                switch self.prepareURLRequest(options: options,
                                              childObjects: childObjects,
                                              childFiles: childFiles) {
                case .success(let urlRequest):
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
                case .failure(let error):
                    completion(.failure(error))
                }
            } else {
                //ParseFiles are handled with a dedicated URLSession
                let session: URLSession!
                let delegate: URLSessionDelegate!
                if method == .POST || method == .PUT {
                    switch self.prepareURLRequest(options: options,
                                                  childObjects: childObjects,
                                                  childFiles: childFiles) {

                    case .success(let urlRequest):
                        if !ParseConfiguration.isTestingSDK {
                            delegate = ParseURLSessionDelegate(callbackQueue: callbackQueue,
                                                               uploadProgress: uploadProgress)
                            session = URLSession(configuration: .default,
                                                 delegate: delegate,
                                                 delegateQueue: nil)
                        } else {
                            session = URLSession.testing
                        }
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
                    case .failure(let error):
                        completion(.failure(error))
                    }
                } else {

                    if !ParseConfiguration.isTestingSDK {
                        delegate = ParseURLSessionDelegate(callbackQueue: callbackQueue,
                                                           downloadProgress: downloadProgress)
                        session = URLSession(configuration: .default,
                                             delegate: delegate,
                                             delegateQueue: nil)
                    } else {
                        session = URLSession.testing
                    }
                    if parseURL != nil {
                        switch self.prepareURLRequest(options: options,
                                                      childObjects: childObjects,
                                                      childFiles: childFiles) {

                        case .success(let urlRequest):
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
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    } else if let otherURL = self.otherURL {
                        //Non-parse servers don't receive any parse dedicated request info
                        session.downloadTask(with: otherURL, mapper: mapper) { result in
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
                        completion(.failure(ParseError(code: .unknownError,
                                                       message: "Can't download the file without specifying the url")))
                    }
                }
            }
        }

        // MARK: URL Preperation
        func prepareURLRequest(options: API.Options,
                               childObjects: [NSDictionary: PointerType]? = nil,
                               childFiles: [UUID: ParseFile]? = nil) -> Result<URLRequest, ParseError> {
            let params = self.params?.getQueryItems()
            let headers = API.getHeaders(options: options)
            let url = parseURL == nil ?
                ParseConfiguration.serverURL.appendingPathComponent(path.urlComponent) : parseURL!

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
                                    objectsSavedBeforeThisOne: childObjects, filesSavedBeforeThisOne: childFiles) else {
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
    // MARK: Uploading File
    static func uploadFileCommand(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        if object.isSaved {
            return updateFileCommand(object)
        }
        return createFileCommand(object)
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
                    parseURL: object.url,
                    otherURL: object.cloudURL) { (data) -> ParseFile in
            let tempFileLocation = try ParseCoding.jsonDecoder().decode(URL.self, from: data)
            guard let fileManager = ParseFileManager(),
                  let defaultDirectoryPath = fileManager.defaultDataDirectoryPath else {
                throw ParseError(code: .unknownError, message: "Can't create fileManager")
            }
            let downloadDirectoryPath = defaultDirectoryPath
                .appendingPathComponent(ParseConstants.fileDownloadsDirectory, isDirectory: true)
            try fileManager.createDirectoryIfNeeded(downloadDirectoryPath.relativePath)
            let fileLocation = downloadDirectoryPath.appendingPathComponent(object.name)
            try? FileManager.default.removeItem(at: fileLocation) //Remove file if it's already present
            try FileManager.default.moveItem(at: tempFileLocation, to: fileLocation)
            var object = object
            object.localURL = fileLocation
            _ = object.localUUID //Ensure downloaded file has a localUUID
            return object
        }
    }

    // MARK: Deleting File
    static func deleteFileCommand(_ object: ParseFile) -> API.Command<ParseFile, NoBody> {
        API.Command(method: .DELETE,
                    path: .file(fileName: object.name),
                    parseURL: object.url) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }

    // MARK: Saving ParseObjects
    static func saveCommand<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        if object.isSaved {
            return updateCommand(object)
        }
        return createCommand(object)
    }

    // MARK: Saving ParseObjects - private
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

    // MARK: Saving ParseObjects - Encodable
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

    // MARK: Saving ParseObjects - Encodable - private
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
    static func deleteCommand<T>(_ object: T) throws -> API.Command<NoBody, ParseError?> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.Command<NoBody, ParseError?>(
            method: .DELETE,
            path: object.endpoint
        ) { (data) -> ParseError? in
            try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
        }
    }
}

// MARK: Batch - Saving, Fetching
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

    // MARK: Batch - Deleting
    static func batch(commands: [API.Command<NoBody, ParseError?>]) -> RESTBatchCommandNoBodyType<ParseError?> {
        let commands = commands.compactMap { (command) -> API.Command<NoBody, ParseError?>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
            return API.Command<NoBody, ParseError?>(
                method: command.method,
                path: .any(path), mapper: command.mapper)
        }

        let mapper = { (data: Data) -> [ParseError?] in

            let decodingType = [ParseError?].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return responses.enumerated().map({ (object) -> ParseError? in
                    let response = responses[object.offset]
                    if let error = response {
                        return error
                    } else {
                        return nil
                    }
                })
            } catch {
                guard (try? ParseCoding.jsonDecoder().decode(NoBody.self, from: data)) != nil else {
                    return [ParseError(code: .unknownError, message: "decoding error: \(error)")]
                }
                return [nil]
            }
        }

        let batchCommand = BatchCommand(requests: commands)
        return RESTBatchCommandNoBodyType<ParseError?>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}

// MARK: Batch - Child Objects
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
