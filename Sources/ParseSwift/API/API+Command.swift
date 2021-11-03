//
//  API+Command.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {
    // MARK: API.Command
    struct Command<T, U>: Encodable where T: ParseType {
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
                           callbackQueue: DispatchQueue,
                           childObjects: [String: PointerType]? = nil,
                           childFiles: [UUID: ParseFile]? = nil,
                           uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                           stream: InputStream) throws {
            switch self.prepareURLRequest(options: options, childObjects: childObjects, childFiles: childFiles) {

            case .success(let urlRequest):
                if method == .POST || method == .PUT || method == .PATCH {
                    let task = URLSession.parse.uploadTask(withStreamedRequest: urlRequest)
                    ParseSwift.sessionDelegate.uploadDelegates[task] = uploadProgress
                    ParseSwift.sessionDelegate.streamDelegates[task] = stream
                    ParseSwift.sessionDelegate.taskCallbackQueues[task] = callbackQueue
                    task.resume()
                    return
                }
            case .failure(let error):
                throw error
            }
        }

        func execute(options: API.Options,
                     callbackQueue: DispatchQueue,
                     childObjects: [String: PointerType]? = nil,
                     childFiles: [UUID: ParseFile]? = nil,
                     uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil) throws -> U {
            var responseResult: Result<U, ParseError>?
            let group = DispatchGroup()
            group.enter()
            self.executeAsync(options: options,
                              callbackQueue: callbackQueue,
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
        func executeAsync(options: API.Options,
                          callbackQueue: DispatchQueue,
                          childObjects: [String: PointerType]? = nil,
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
            } else {
                //ParseFiles are handled with a dedicated URLSession
                if method == .POST || method == .PUT || method == .PATCH {
                    switch self.prepareURLRequest(options: options,
                                                  childObjects: childObjects,
                                                  childFiles: childFiles) {

                    case .success(let urlRequest):

                        URLSession
                            .parse
                            .uploadTask(callbackQueue: callbackQueue,
                                        with: urlRequest,
                                        from: uploadData,
                                        from: uploadFile,
                                        progress: uploadProgress,
                                        mapper: mapper) { result in
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
                } else if method == .DELETE {

                    switch self.prepareURLRequest(options: options,
                                                  childObjects: childObjects,
                                                  childFiles: childFiles) {
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

                } else {

                    if parseURL != nil {
                        switch self.prepareURLRequest(options: options,
                                                      childObjects: childObjects,
                                                      childFiles: childFiles) {

                        case .success(let urlRequest):
                            URLSession
                                .parse
                                .downloadTask(callbackQueue: callbackQueue,
                                              with: urlRequest,
                                              progress: downloadProgress,
                                              mapper: mapper) { result in
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
                    } else if let otherURL = self.otherURL {
                        //Non-parse servers don't receive any parse dedicated request info
                        var request = URLRequest(url: otherURL)
                        request.cachePolicy = requestCachePolicy(options: options)
                        URLSession.parse.downloadTask(with: request, mapper: mapper) { result in
                            switch result {

                            case .success(let decoded):
                                completion(.success(decoded))
                            case .failure(let error):
                                completion(.failure(error))
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
                               childObjects: [String: PointerType]? = nil,
                               childFiles: [UUID: ParseFile]? = nil) -> Result<URLRequest, ParseError> {
            let params = self.params?.getQueryItems()
            var headers = API.getHeaders(options: options)
            if !(method == .POST) && !(method == .PUT) && !(method == .PATCH) {
                headers.removeValue(forKey: "X-Parse-Request-Id")
            }
            let url = parseURL == nil ?
                ParseSwift.configuration.serverURL.appendingPathComponent(path.urlComponent) : parseURL!

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
                if (urlBody as? CloudType) != nil {
                    guard let bodyData = try? ParseCoding.parseEncoder().encode(urlBody, skipKeys: .cloud) else {
                        return .failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)"))
                    }
                    urlRequest.httpBody = bodyData
                } else {
                    guard let bodyData = try? ParseCoding
                            .parseEncoder()
                            .encode(urlBody, collectChildren: false,
                                    objectsSavedBeforeThisOne: childObjects,
                                    filesSavedBeforeThisOne: childFiles) else {
                            return .failure(ParseError(code: .unknownError,
                                                       message: "couldn't encode body \(urlBody)"))
                    }
                    urlRequest.httpBody = bodyData.encoded
                }
            }
            urlRequest.httpMethod = method.rawValue
            urlRequest.cachePolicy = requestCachePolicy(options: options)
            return .success(urlRequest)
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }

    static func requestCachePolicy(options: API.Options) -> URLRequest.CachePolicy {
        var policy: URLRequest.CachePolicy = ParseSwift.configuration.requestCachePolicy
        options.forEach { option in
            if case .cachePolicy(let updatedPolicy) = option {
                policy = updatedPolicy
            }
        }
        return policy
    }
}

internal extension API.Command {

    // MARK: Uploading File
    static func uploadFile(_ object: ParseFile) throws -> API.Command<ParseFile, ParseFile> {
        if !object.isSaved {
            return createFile(object)
        } else {
            throw ParseError(code: .unknownError,
                             message: "File is already saved and cannot be updated.")
        }
    }

    // MARK: Uploading File - private
    private static func createFile(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .POST,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    // MARK: Downloading File
    static func downloadFile(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
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
            if tempFileLocation != fileLocation {
                try? FileManager.default.removeItem(at: fileLocation) //Remove file if it's already present
                try FileManager.default.moveItem(at: tempFileLocation, to: fileLocation)
            }
            var object = object
            object.localURL = fileLocation
            return object
        }
    }

    // MARK: Deleting File
    static func deleteFile(_ object: ParseFile) -> API.Command<ParseFile, NoBody> {
        API.Command(method: .DELETE,
                    path: .file(fileName: object.name),
                    parseURL: object.url) { (data) -> NoBody in
            let parseError: ParseError!
            do {
                parseError = try ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            } catch {
                return try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
            }
            throw parseError
        }
    }

    // MARK: Saving ParseObjects
    static func save<T>(_ object: T,
                        isIgnoreCustomObjectIdConfig: Bool) throws -> API.Command<T, T> where T: ParseObject {
        if ParseSwift.configuration.allowCustomObjectId && object.objectId == nil && !isIgnoreCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
        if object.isSaved {
            return update(object)
        }
        return create(object)
    }

    // MARK: Saving ParseObjects - private
    private static func create<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        let mapper = { (data) -> T in
            try ParseCoding.jsonDecoder().decode(SaveResponse.self, from: data).apply(to: object)
        }
        return API.Command<T, T>(method: .POST,
                                 path: object.endpoint(.POST),
                                 body: object,
                                 mapper: mapper)
    }

    private static func update<T>(_ object: T) -> API.Command<T, T> where T: ParseObject {
        let mapper = { (data) -> T in
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: data).apply(to: object)
        }
        return API.Command<T, T>(method: .PUT,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Fetching
    static func fetch<T>(_ object: T, include: [String]?) throws -> API.Command<T, T> where T: ParseObject {
        guard object.objectId != nil else {
            throw ParseError(code: .unknownError, message: "Cannot Fetch an object without id")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(includeParams)"]
        }

        return API.Command<T, T>(
            method: .GET,
            path: object.endpoint,
            params: params
        ) { (data) -> T in
            try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }
    }
}

internal extension API.Command where T: ParseObject {

    // MARK: Batch - Saving, Fetching
    static func batch(commands: [API.Command<T, T>],
                      transaction: Bool) -> RESTBatchCommandType<T> {
        let batchCommands = commands.compactMap { (command) -> API.Command<T, T>? in
            let path = ParseSwift.configuration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return API.Command<T, T>(method: command.method, path: .any(path),
                                     body: body, mapper: command.mapper)
        }

        let mapper = { (data: Data) -> [Result<T, ParseError>] in

            let decodingType = [BatchResponseItem<WriteResponse>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return commands.enumerated().map({ (object) -> (Result<T, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success,
                       let body = object.element.body {
                        return .success(success.apply(to: body, method: object.element.method))
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

        let batchCommand = BatchCommand(requests: batchCommands, transaction: transaction)
        return RESTBatchCommandType<T>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }

    // MARK: Batch - Deleting
    static func batch(commands: [API.NonParseBodyCommand<NoBody, NoBody>],
                      transaction: Bool) -> RESTBatchCommandNoBodyType<NoBody> {
        let commands = commands.compactMap { (command) -> API.NonParseBodyCommand<NoBody, NoBody>? in
            let path = ParseSwift.configuration.mountPath + command.path.urlComponent
            return API.NonParseBodyCommand<NoBody, NoBody>(
                method: command.method,
                path: .any(path), mapper: command.mapper)
        }

        let mapper = { (data: Data) -> [(Result<Void, ParseError>)] in

            let decodingType = [BatchResponseItem<NoBody>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return responses.enumerated().map({ (object) -> (Result<Void, ParseError>) in
                    let response = responses[object.offset]
                    if response.success != nil {
                        return .success(())
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

        let batchCommand = BatchCommandNoBody(requests: commands, transaction: transaction)
        return RESTBatchCommandNoBodyType<NoBody>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}
