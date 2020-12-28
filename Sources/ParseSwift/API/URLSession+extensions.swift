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

class ParseURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate
{

    var downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    var uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)?
    var stream: InputStream?
    var callbackQueue: DispatchQueue?

    init (callbackQueue: DispatchQueue?, uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
          downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil,
          stream: InputStream? = nil) {
        super.init()
        self.callbackQueue = callbackQueue
        self.uploadProgress = uploadProgress
        self.downloadProgress = downloadProgress
        self.stream = stream
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async {
                self.uploadProgress?(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
            }
        } else {
            uploadProgress?(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        downloadProgress = nil
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async {
                self.downloadProgress?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            }
        } else {
            downloadProgress?(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        completionHandler(stream)
    }
}

extension URLSession {

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
        } else if let responseData = responseData {
            do {
                return try .success(mapper(responseData))
            } catch {
                let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: responseData)
                return .failure(parseError ?? ParseError(code: .unknownError,
                                                         // swiftlint:disable:next line_length
                                                         message: "Error decoding parse-server response: \(error.localizedDescription)"))
            }
        } else {
            return .failure(ParseError(code: .unknownError,
                                       // swiftlint:disable:next line_length
                                       message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
        }
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
        } else if let location = location {
            do {
                let data = try ParseCoding.jsonEncoder().encode(location)
                return try .success(mapper(data))
            } catch {
                return .failure(ParseError(code: .unknownError,
                                           // swiftlint:disable:next line_length
                                           message: "Error decoding parse-server response: \(error.localizedDescription)"))
            }
        } else {
            return .failure(ParseError(code: .unknownError,
                                       // swiftlint:disable:next line_length
                                       message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
        }
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

    internal func uploadTask<U>(
        with request: URLRequest,
        from data: Data?,
        from file: URL?,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {

        if let data = data {
            uploadTask(with: request, from: data) { (responseData, urlResponse, responseError) in
                completion(self.makeResult(responseData: responseData,
                                      urlResponse: urlResponse,
                                      responseError: responseError, mapper: mapper))
            }.resume()
        } else if let file = file {
            uploadTask(with: request, fromFile: file) { (responseData, urlResponse, responseError) in
                completion(self.makeResult(responseData: responseData,
                                      urlResponse: urlResponse,
                                      responseError: responseError, mapper: mapper))
            }.resume()
        } else {
            completion(.failure(ParseError(code: .unknownError, message: "data and file both can't be nil")))
        }
    }

    internal func downloadTask<U>(
        with request: URLRequest,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {

        downloadTask(with: request) { (location, urlResponse, responseError) in
            completion(self.makeResult(location: location,
                                  urlResponse: urlResponse,
                                  responseError: responseError, mapper: mapper))
        }.resume()
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

internal extension URLSession {
    static var testing = URLSession.shared
}
