//
//  MockURLResponse.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/18/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
@testable import ParseSwift

struct MockURLResponse {
    var statusCode: Int = 0
    var headerFields = [String: String]()
    var responseData: Data?
    var delay: TimeInterval!
    var error: ParseError?

    init(error: ParseError?) {
        self.delay = .init(0.0)
        self.error = error
        self.responseData = nil
    }

    init(string: String) throws {
        try self.init(string: string, statusCode: 200, delay: .init(0.0))
    }

    init(string: String, statusCode: Int, delay: TimeInterval,
         headerFields: [String: String] = ["Content-Type": "application/json"]) throws {
        guard let data = string.data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "unable to convert string to data")
        }
        self.init(data: data, statusCode: statusCode, delay: delay, headerFields: headerFields)
        self.error = nil
    }

    init(data: Data, statusCode: Int, delay: TimeInterval,
         headerFields: [String: String] = ["Content-Type": "application/json"]) {
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.responseData = data
        self.delay = delay
        self.error = nil
    }
}
