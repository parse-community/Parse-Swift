//
//  URLSession.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/22/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

extension URLSession {

    internal func dataTask(with request: URLRequest,
                           completion: @escaping(Result<Data, ParseError>) -> Void) {

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
        }.resume()
    }
}
