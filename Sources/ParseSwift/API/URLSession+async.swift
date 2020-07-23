//
//  URLSession+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/22/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import Combine

extension URLSession {

    internal func asyncDataTask(with request: URLRequest,
                                completion: @escaping(Result<Data, ParseError>) -> Void) {

        let semaphore = DispatchSemaphore(value: 0)
        dataTask(with: request) { (responseData, urlResponse, responseError) in

            guard let responseData = responseData else {
                guard let error = responseError as? ParseError else {
                    completion(.failure(ParseError(code: .unknownError,
                                               message: "Unable to sync data: \(String(describing: urlResponse)).")))
                    return
                }
                completion(.failure(error))
                return
            }

            completion(.success(responseData))
            semaphore.signal()
        }.resume()
        semaphore.wait()
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    internal func asyncDataTask(with request: URLRequest) -> Future<Data, ParseError> {

        return Future<Data, ParseError> { promise in
            let semaphore = DispatchSemaphore(value: 0)
            _ = self.dataTask(with: request) { (responseData, urlResponse, responseError) in

                guard let responseData = responseData else {
                    guard let error = responseError as? ParseError else {
                        promise(.failure(ParseError(code: .unknownError,
                                                    message: "Unable to sync: \(String(describing: urlResponse)).")))
                        return
                    }
                    promise(.failure(error))
                    return
                }

                promise(.success(responseData))
                semaphore.signal()
            }.resume()
            semaphore.wait()
            /*
            let semaphore = DispatchSemaphore(value: 0)
            let test = self.dataTaskPublisher(for: request).map { data, response -> Void in
                guard let httpResponse = response as? HTTPURLResponse,
                     200...299 ~= httpResponse.statusCode else {
                        promise(.failure(ParseError(code: .unknownError, message: "Unable to async: \(response).")))
                        semaphore.signal()
                        return
                }
                promise(.success(data))
                semaphore.signal()
                //return data

            }/*.sink(receiveCompletion: { (errorCompletion) in
                if case let .failure(error) = errorCompletion {
                    switch error {
                    case let parseError as ParseError:
                        promise(.failure(parseError))
                    default:
                        promise(.failure(ParseError(code: .unknownError,
                                                    message: "Unable to connect to subscriber in async.")))
                    }
                }
                //semaphore.signal()
            }, receiveValue: { data -> Void in
                promise(.success(data))
                //semaphore.signal()
            })*/
            semaphore.wait()*/
        }
    }

}
