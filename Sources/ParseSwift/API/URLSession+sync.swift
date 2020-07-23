//
//  URLSession+sync.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

extension URLSession {
    internal func syncDataTask(with request: URLRequest) throws -> Result<Data, ParseError> {
        let semaphore = DispatchSemaphore(value: 0)
        var data: Data?
        var error: Error?
        var response: URLResponse?
        dataTask(with: request) { (responseData, urlResponse, responseError) in
            data = responseData
            error = responseError
            response = urlResponse
            semaphore.signal()
            }.resume()
        semaphore.wait()
        guard let responseData = data else {
            guard let error = error as? ParseError else {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync data: \(String(describing: response))."))
            }
            return .failure(error)
        }
        return .success(responseData)
    }

}
