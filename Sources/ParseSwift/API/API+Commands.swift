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

// MARK: API.Command
internal extension API {
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
                if method == .POST || method == .PUT {
                    let task = URLSession.parse.uploadTask(withStreamedRequest: urlRequest)
                    ParseConfiguration.sessionDelegate.uploadDelegates[task] = uploadProgress
                    ParseConfiguration.sessionDelegate.streamDelegates[task] = stream
                    ParseConfiguration.sessionDelegate.taskCallbackQueues[task] = callbackQueue
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
                if method == .POST || method == .PUT {
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
                        URLSession.parse.downloadTask(with: otherURL, mapper: mapper) { result in
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
                if (urlBody as? ParseCloud) != nil {
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
        let mapper = { (data) -> T in
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
            return try objectable.toPointer()
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
            return try objectable.toPointer()
        }
        return API.Command<T, PointerType>(method: .PUT,
                                 path: objectable.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Fetching
    static func fetchCommand<T>(_ object: T, include: [String]?) throws -> API.Command<T, T> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Fetch an object without id")
        }

        var params: [String: String]?
        if let includeParams = include {
            let joined = includeParams.joined(separator: ",")
            params = ["include": joined]
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

// MARK: Batch - Saving, Fetching
extension API.Command where T: ParseObject {

    internal var data: Data? {
        guard let body = body else { return nil }
        return try? body.getEncoder().encode(body, skipKeys: .object)
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
    static func batch(commands: [API.NonParseBodyCommand<NoBody, NoBody>]) -> RESTBatchCommandNoBodyType<NoBody> {
        let commands = commands.compactMap { (command) -> API.NonParseBodyCommand<NoBody, NoBody>? in
            let path = ParseConfiguration.mountPath + command.path.urlComponent
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

        let batchCommand = BatchCommandNoBody(requests: commands)
        return RESTBatchCommandNoBodyType<NoBody>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}

//This has been disabled, looking into getting it working in the future.
//It's only needed for sending batches of childObjects which currently isn't being used.
/*
// MARK: Batch - Child Objects
extension API.Command where T: ParseType {

    internal var data: Data? {
        guard let body = body else { return nil }
        return try? ParseCoding.jsonEncoder().encode(body)
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
}*/

// MARK: API.NonParseBodyCommand
internal extension API {
    struct NonParseBodyCommand<T, U>: Encodable where T: Encodable {
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
                guard let bodyData = try? ParseCoding.jsonEncoder().encode(urlBody) else {
                    return .failure(ParseError(code: .unknownError,
                                                   message: "couldn't encode body \(urlBody)"))
                }
                urlRequest.httpBody = bodyData
            }
            urlRequest.httpMethod = method.rawValue

            return .success(urlRequest)
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}

internal extension API.NonParseBodyCommand {
    // MARK: Deleting
    static func deleteCommand<T>(_ object: T) throws -> API.NonParseBodyCommand<NoBody, NoBody> where T: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .unknownError, message: "Cannot Delete an object without id")
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(
            method: .DELETE,
            path: object.endpoint
        ) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }
} // swiftlint:disable:this file_length
