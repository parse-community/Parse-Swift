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

    internal func dataTask<U>(
        with request: URLRequest,
        mapper: @escaping (Data) throws -> U,
        completion: @escaping(Result<U, ParseError>) -> Void
    ) {
        func makeResult(responseData: Data?, urlResponse: URLResponse?,
                        responseError: Error?) -> Result<U, ParseError> {
            if let responseData = responseData {
                do {
                    return try .success(mapper(responseData))
                } catch {
                    let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: responseData)
                    return .failure(parseError ?? ParseError(code: .unknownError,
                                                             // swiftlint:disable:next line_length
                                                             message: "Error decoding parse-server response: \(error.localizedDescription)"))
                }
            } else if let responseError = responseError {
                return .failure(ParseError(code: .unknownError,
                                           message: "Unable to sync with parse-server: \(responseError)"))
            } else {
                return .failure(ParseError(code: .unknownError,
                                           // swiftlint:disable:next line_length
                                           message: "Unable to sync with parse-server: \(String(describing: urlResponse))."))
            }
        }

        dataTask(with: request) { (responseData, urlResponse, responseError) in
            let result = makeResult(responseData: responseData, urlResponse: urlResponse, responseError: responseError)
            completion(result)
        }.resume()
    }
}
