//
//  URLSession.swift
//  ParseSwift
//
//  Original file, URLSession+sync.swift, created by Florent Vilmart on 17-09-24.
//  Name change to URLSession.swift and support for sync/async by Corey Baker on 7/25/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension URLSession {
    static let parse: URLSession = {
        if !ParseSwift.configuration.isTestingSDK {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = URLCache.parse
            configuration.requestCachePolicy = ParseSwift.configuration.requestCachePolicy
            configuration.httpAdditionalHeaders = ParseSwift.configuration.httpAdditionalHeaders
            return URLSession(configuration: configuration,
                   delegate: ParseSwift.sessionDelegate,
                   delegateQueue: nil)
        } else {
            let session = URLSession.shared
            session.configuration.urlCache = URLCache.parse
            return URLSession.shared
        }
    }()

    func makeResult<U>(request: URLRequest,
                       responseData: Data?,
                       urlResponse: URLResponse?,
                       responseError: Error?,
                       mapper: @escaping (Data) throws -> U) -> Result<U, ParseError> {
        guard let response = urlResponse else {
            guard let parseError = responseError as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "No response from server"))
            }
            return .failure(parseError)
        }
        if let responseError = responseError {
            guard let parseError = responseError as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync with parse-server: \(responseError)"))
            }
            return .failure(parseError)
        }

        if let responseData = responseData {
            do {
                if URLSession.parse.configuration.urlCache?.cachedResponse(for: request) == nil {
                    URLSession.parse.configuration.urlCache?.storeCachedResponse(.init(response: response,
                                                              data: responseData),
                                                        for: request)
                }
                return try .success(mapper(responseData))
            } catch {
                if let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: responseData) {
                    return .failure(error)
                }
                guard let parseError = error as? ParseError else {
                    guard JSONSerialization.isValidJSONObject(responseData) == true,
                          let json = try? JSONSerialization
                            .data(withJSONObject: responseData,
                              options: .prettyPrinted) else {
                        let nsError = error as NSError
                        if nsError.code == 4865,
                          let description = nsError.userInfo["NSDebugDescription"] {
                            return .failure(ParseError(code: .unknownError, message: "Invalid struct: \(description)"))
                        }
                        return .failure(ParseError(code: .unknownError,
                                                   // swiftlint:disable:next line_length
                                                   message: "Error decoding parse-server response: \(response) with error: \(error.localizedDescription) Format: \(String(describing: String(data: responseData, encoding: .utf8)))"))
                    }
                    return .failure(ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "Error decoding parse-server response: \(response) with error: \(error.localizedDescription) Format: \(String(describing: String(data: json, encoding: .utf8)))"))
                }
                return .failure(parseError)
            }
        }

        return .failure(ParseError(code: .unknownError,
                                   message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
    }

    func makeResult<U>(request: URLRequest,
                       location: URL?,
                       urlResponse: URLResponse?,
                       responseError: Error?,
                       mapper: @escaping (Data) throws -> U) -> Result<U, ParseError> {
        guard let response = urlResponse else {
            guard let parseError = responseError as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "No response from server"))
            }
            return .failure(parseError)
        }
        if let responseError = responseError {
            guard let parseError = responseError as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync with parse-server: \(responseError)"))
            }
            return .failure(parseError)
        }

        if let location = location {
            do {
                let data = try ParseCoding.jsonEncoder().encode(location)
                return try .success(mapper(data))
            } catch {
                guard let parseError = error as? ParseError else {
                    return .failure(ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "Error decoding parse-server response: \(response) with error: \(error.localizedDescription)"))
                }
                return .failure(parseError)
            }
        }

        return .failure(ParseError(code: .unknownError,
                                   message: "Unable to sync with parse-server: \(response)."))
    }

    func dataTask<U>(
        with request: URLRequest,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {

        dataTask(with: request) { (responseData, urlResponse, responseError) in
            completion(self.makeResult(request: request,
                                       responseData: responseData,
                                       urlResponse: urlResponse,
                                       responseError: responseError,
                                       mapper: mapper))
        }.resume()
    }
}

internal extension URLSession {
    func uploadTask<U>( // swiftlint:disable:this function_parameter_count
        callbackQueue: DispatchQueue,
        with request: URLRequest,
        from data: Data?,
        from file: URL?,
        progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)?,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        var task: URLSessionTask?
        if let data = data {
            task = uploadTask(with: request, from: data) { (responseData, urlResponse, responseError) in
                completion(self.makeResult(request: request,
                                           responseData: responseData,
                                           urlResponse: urlResponse,
                                           responseError: responseError, mapper: mapper))
            }
        } else if let file = file {
            task = uploadTask(with: request, fromFile: file) { (responseData, urlResponse, responseError) in
                completion(self.makeResult(request: request,
                                           responseData: responseData,
                                           urlResponse: urlResponse,
                                           responseError: responseError, mapper: mapper))
            }
        } else {
            completion(.failure(ParseError(code: .unknownError, message: "data and file both can't be nil")))
        }
        if let task = task {
            ParseSwift.sessionDelegate.uploadDelegates[task] = progress
            ParseSwift.sessionDelegate.taskCallbackQueues[task] = callbackQueue
            task.resume()
        }
    }

    func downloadTask<U>(
        callbackQueue: DispatchQueue,
        with request: URLRequest,
        progress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        let task = downloadTask(with: request) { (location, urlResponse, responseError) in
            let result = self.makeResult(request: request,
                                         location: location,
                                         urlResponse: urlResponse,
                                         responseError: responseError, mapper: mapper)
            if case .success(let file) = result {
                guard let response = urlResponse,
                      let parseFile = file as? ParseFile,
                      let fileLocation = parseFile.localURL,
                      let data = try? ParseCoding.jsonEncoder().encode(fileLocation) else {
                          completion(result)
                          return
                }
                if URLSession.parse.configuration.urlCache?.cachedResponse(for: request) == nil {
                    URLSession.parse.configuration.urlCache?
                        .storeCachedResponse(.init(response: response,
                                                   data: data),
                                             for: request)
                }
            }
            completion(result)
        }
        ParseSwift.sessionDelegate.downloadDelegates[task] = progress
        ParseSwift.sessionDelegate.taskCallbackQueues[task] = callbackQueue
        task.resume()
    }

    func downloadTask<U>(
        with request: URLRequest,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        downloadTask(with: request) { (location, urlResponse, responseError) in
            completion(self.makeResult(request: request, location: location,
                                       urlResponse: urlResponse,
                                       responseError: responseError,
                                       mapper: mapper))
        }.resume()
    }
}
