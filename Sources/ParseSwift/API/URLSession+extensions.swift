//
//  URLSession+extensions.swift
//  ParseSwift
//
//  Original file, URLSession+sync.swift, created by Florent Vilmart on 17-09-24.
//  Name change to URLSession+extensions.swift and support for sync/async by Corey Baker on 7/25/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
    static let parse: URLSession = {
        if !ParseSwift.configuration.isTestingSDK {
            return URLSession(configuration: .default,
                   delegate: ParseSwift.sessionDelegate,
                   delegateQueue: nil)
        } else {
            return URLSession.shared
        }
    }()

    internal func makeResult<U>(responseData: Data?,
                                urlResponse: URLResponse?,
                                responseError: Error?,
                                mapper: @escaping (Data) throws -> U) -> Result<U, ParseError> {
        if let responseError = responseError {
            guard let parseError = responseError as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync with parse-server: \(responseError)"))
            }
            return .failure(parseError)
        }

        if let responseData = responseData {
            do {
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
                        return .failure(ParseError(code: .unknownError,
                                                   // swiftlint:disable:next line_length
                                                   message: "Error decoding parse-server response: \(String(describing: urlResponse)) with error: \(error.localizedDescription) Format: \(String(describing: String(data: responseData, encoding: .utf8)))"))
                    }
                    return .failure(ParseError(code: .unknownError,
                                               // swiftlint:disable:next line_length
                                               message: "Error decoding parse-server response: \(String(describing: urlResponse)) with error: \(error.localizedDescription) Format: \(String(describing: String(data: json, encoding: .utf8)))"))
                }
                return .failure(parseError)
            }
        }

        return .failure(ParseError(code: .unknownError,
                                   message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
    }

    internal func makeResult<U>(location: URL?,
                                urlResponse: URLResponse?,
                                responseError: Error?,
                                mapper: @escaping (Data) throws -> U) -> Result<U, ParseError> {
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
                                               message: "Error decoding parse-server response: \(String(describing: urlResponse)) with error: \(error.localizedDescription)"))
                }
                return .failure(parseError)
            }
        }

        return .failure(ParseError(code: .unknownError,
                                   message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
    }

    internal func dataTask<U>(
        with request: URLRequest,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {

        dataTask(with: request) { (responseData, urlResponse, responseError) in
            completion(self.makeResult(responseData: responseData,
                                  urlResponse: urlResponse,
                                  responseError: responseError, mapper: mapper))
        }.resume()
    }
}

extension URLSession {
    internal func uploadTask<U>( // swiftlint:disable:this function_parameter_count
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
                completion(self.makeResult(responseData: responseData,
                                      urlResponse: urlResponse,
                                      responseError: responseError, mapper: mapper))
            }
        } else if let file = file {
            task = uploadTask(with: request, fromFile: file) { (responseData, urlResponse, responseError) in
                completion(self.makeResult(responseData: responseData,
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

    internal func downloadTask<U>(
        callbackQueue: DispatchQueue,
        with request: URLRequest,
        progress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        let task = downloadTask(with: request) { (location, urlResponse, responseError) in
            completion(self.makeResult(location: location,
                                  urlResponse: urlResponse,
                                  responseError: responseError, mapper: mapper))
        }
        ParseSwift.sessionDelegate.downloadDelegates[task] = progress
        ParseSwift.sessionDelegate.taskCallbackQueues[task] = callbackQueue
        task.resume()
    }

    internal func downloadTask<U>(
        with url: URL,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {

        downloadTask(with: url) { (location, urlResponse, responseError) in
            completion(self.makeResult(location: location,
                                       urlResponse: urlResponse,
                                       responseError: responseError,
                                       mapper: mapper))
        }.resume()
    }
}
