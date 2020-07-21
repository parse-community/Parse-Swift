//
//  APITests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class APITests: XCTestCase {
    /*struct User: ParseSwift.UserType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?
    }
    */
    struct GameScore: ParseSwift.ObjectType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        //: Your own properties
        var score: Int

        //: a custom initializer
        init(score: Int) {
            self.score = score
        }
    }

    override func setUp() {
        super.setUp()
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: URL(string: "http://localhost:1337/1")!)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParseError() {
        let originalError = ParseError(code: .connectionFailed, message: "no connection")
        MockURLProtocol.mockRequests { response in
            let response = MockURLResponse(error: originalError)
            return response
        }
        do {
            let score = GameScore(score: 10)
            _ = try score.save()
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    func testUnknownError() {
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100500
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        MockURLProtocol.mockRequests { response in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                let response = MockURLResponse(data: json, statusCode: 400, delay: 0.0)
                return response
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }
        do {
            let score = GameScore(score: 10)
            _ = try score.save()
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("should be able unwrap final error to ParseError")
                return
            }
            let unknownError = ParseError(code: .unknownError, message: "")
            XCTAssertEqual(unknownError.code, error.code)
        }
    }
}
