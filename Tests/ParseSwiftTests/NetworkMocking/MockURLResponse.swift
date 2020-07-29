//
//  MockURLResponse.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/18/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
@testable import ParseSwift

struct MockURLResponse {
    var statusCode: Int = 200
    var headerFields = [String: String]()
    var responseData: Data?
    var delay: TimeInterval!
    var error: Error?

    init(error: Error) {
        self.delay = .init(0.0)
        self.error = error
        self.responseData = nil
        self.statusCode = 400
    }

    init(string: String) throws {
        try self.init(string: string, statusCode: 200, delay: .init(0.0))
    }

    init(string: String, statusCode: Int, delay: TimeInterval,
         headerFields: [String: String] = ["Content-Type": "application/json"]) throws {

        do {
            let encoded = try JSONEncoder().encode(string)
            self.init(data: encoded, statusCode: statusCode, delay: delay, headerFields: headerFields)
        } catch {
            throw ParseError(code: .unknownError, message: "unable to convert string to data")
        }
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
