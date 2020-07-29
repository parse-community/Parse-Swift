//
//  URLSession+extensions.swift
//  ParseSwift
//
//  Original file, URLSession+async.swift, created by Florent Vilmart on 17-09-24.
//  Name change to URLSession+extensions.swift and support for sync/async by Corey Baker on 7/25/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

extension URLSession {

    internal func dataTask(with request: URLRequest, callbackQueue: DispatchQueue?,
                           completion: @escaping(Result<Data, ParseError>) -> Void) {

        dataTask(with: request) { (responseData, urlResponse, responseError) in

            guard let callbackQueue = callbackQueue else {
                guard let responseData = responseData else {
                    guard let error = responseError else {
                        completion(.failure(ParseError(code: .unknownError,
                                                       message: "Unable to sync: \(String(describing: urlResponse)).")))
                        return
                    }
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: "Unable to sync: \(error).")))
                    return
                }

                completion(.success(responseData))
                return
            }

            guard let responseData = responseData else {
                guard let error = responseError else {
                        callbackQueue.async {
                            completion(.failure(ParseError(code: .unknownError,
                                                           message: "Unable to sync: \(String(describing: urlResponse))."))) // swiftlint:disable:this line_length
                        }

                    return
                }
                callbackQueue.async {
                    completion(.failure(ParseError(code: .unknownError,
                                                   message: "Unable to sync: \(error).")))
                }
                return
            }

            callbackQueue.async { completion(.success(responseData)) }

        }.resume()
    }
}
