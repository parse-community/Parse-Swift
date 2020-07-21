//
//  APICommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class APICommandTests: XCTestCase {

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
    }

    func testConstructors() {
        let api =
            API.Command<NoBody, String>(method: .GET, path: .login,
                                        params: ["test": "test"], body: NoBody(), mapper: { (data) -> String in
                return try JSONDecoder().decode(String.self, from: data)
        })
        XCTAssertNotNil(api)

        let api2 = API.Command<NoBody, String>(method: .GET, path: .login, params: nil, mapper: { (data) -> String in
                return try JSONDecoder().decode(String.self, from: data)
        })
        XCTAssertNotNil(api2)
    }

    func testExecuteCorrectly() {
        let originalObject = "test"
        MockURLProtocol.mockRequests { response in
            do {
                let response = try MockURLResponse(string: originalObject, statusCode: 0, delay: 0.0)
                return response
            } catch {
                return nil
            }
        }
        do {
            let returnedObject =
                try API.Command<NoBody, String>(method: .GET, path: .login, params: nil, mapper: { (data) -> String in
                    return try JSONDecoder().decode(String.self, from: data)
            }).execute(options: [])
            XCTAssertEqual(originalObject, returnedObject)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testErrorServer() {
        let originalError = ParseError(code: .connectionFailed, message: "no connection")
        MockURLProtocol.mockRequests { response in
            let response = MockURLResponse(error: originalError)
            return response
        }
        do {
            _ = try API.Command<NoBody, NoBody>(method: .GET, path: .login, params: nil, mapper: { (data) -> NoBody in
                    return try JSONDecoder().decode(NoBody.self, from: data)
            }).execute(options: [])
            //let score = GameScore(score: 10)
            //_ = try score.save()
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    func testAPIError() {
        let originalError = ParseError(code: .unknownError, message: "Couldn't decode")
        MockURLProtocol.mockRequests { response in
            let response = MockURLResponse(error: originalError)
            return response
        }
        do {
            _ = try API.Command<NoBody, NoBody>(method: .GET, path: .login, params: nil, mapper: { (_) -> NoBody in
                throw originalError
            }).execute(options: [])
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    func testNotParseErrorType() {
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
            _ = try API.Command<NoBody, NoBody>(method: .GET, path: .login, params: nil, mapper: { (_) -> NoBody in
                    throw ParseError(code: .connectionFailed, message: "Connection failed")
            }).execute(options: [])
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
