//
//  ParseHookResponseTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseHookResponseTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testInitializers() throws {
        let response1 = ParseHookResponse<String>(success: "test")
        XCTAssertNotNil(response1.success)
        XCTAssertNil(response1.code)
        XCTAssertNil(response1.message)
        XCTAssertNil(response1.otherCode)
        XCTAssertNil(response1.error)
        let response2 = ParseHookResponse<String>(code: .unknownError, message: "yo")
        XCTAssertNil(response2.success)
        XCTAssertNotNil(response2.code)
        XCTAssertNotNil(response2.message)
        XCTAssertNil(response2.otherCode)
        XCTAssertNil(response2.error)
        let response3 = ParseHookResponse<String>(otherCode: 2000, message: "yo")
        XCTAssertNil(response3.success)
        XCTAssertEqual(response3.code, .other)
        XCTAssertNotNil(response3.message)
        XCTAssertNotNil(response3.otherCode)
        XCTAssertNil(response3.error)
        let response4 = ParseHookResponse<String>(error: .init(code: .unknownError, message: "yup"))
        XCTAssertNil(response4.success)
        XCTAssertNotNil(response4.code)
        XCTAssertNotNil(response4.message)
        XCTAssertNil(response4.otherCode)
        XCTAssertNil(response4.error)
    }

    func testSuccess() throws {
        var response = ParseHookResponse(success: true)
        let expected = "{\"success\":true}"
        XCTAssertEqual(response.description, expected)
        response.message = "yo"
        response.code = .accountAlreadyLinked
        XCTAssertEqual(response.description, expected)
    }

    func testEncode() throws {
        let code = -1
        let message = "testing ParseHookResponse"
        guard let encoded: Data = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseHookResponse<String>.self, from: encoded)
        XCTAssertEqual(decoded.code?.rawValue, code)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.description, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.errorDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
    }

    func testEncodeMessage() throws {
        let code = -1
        let message = "testing ParseHookResponse"
        guard let encoded: Data = "{\"message\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseHookResponse<String>.self, from: encoded)
        XCTAssertEqual(decoded.code?.rawValue, code)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.description, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.errorDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
    }

    func testEncodeOther() throws {
        let code = 2000
        let message = "testing ParseHookResponse"
        guard let encoded = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseHookResponse<String>.self, from: encoded)
        XCTAssertEqual(decoded.code, .other)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription,
                       "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.otherCode, code)
        var response = ParseHookResponse<String>(code: .unknownError, message: "hello")
        response.code = nil
        XCTAssertThrowsError(try ParseCoding.jsonEncoder().encode(response))
    }

    func testConvertError() throws {
        var response = ParseHookResponse<String>()
        response.code = .accountAlreadyLinked
        XCTAssertThrowsError(try response.convertToParseError())
        response.message = "hello"
        XCTAssertNoThrow(try response.convertToParseError())
        response.code = nil
        XCTAssertThrowsError(try response.convertToParseError())
    }

    func testCompare() throws {
        let code = ParseError.Code.objectNotFound.rawValue
        let message = "testing ParseHookResponse"
        guard let encoded = "{\"code\":\(code),\"error\":\"\(message)\"}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseHookResponse<String>.self, from: encoded)

        let error: Error = try decoded.convertToParseError()

        XCTAssertTrue(error.equalsTo(.objectNotFound))
        XCTAssertFalse(error.equalsTo(.invalidQuery))

        XCTAssertTrue(error.containedIn(.objectNotFound, .invalidQuery))
        XCTAssertFalse(error.containedIn(.operationForbidden, .invalidQuery))

        XCTAssertTrue(error.containedIn([.objectNotFound, .invalidQuery]))
        XCTAssertFalse(error.containedIn([.operationForbidden, .invalidQuery]))

        XCTAssertNotNil(error.equalsTo(.objectNotFound))
        XCTAssertNil(error.equalsTo(.invalidQuery))

        XCTAssertNotNil(error.containedIn(.objectNotFound, .invalidQuery))
        XCTAssertNil(error.containedIn(.operationForbidden, .invalidQuery))

        XCTAssertNotNil(error.containedIn([.objectNotFound, .invalidQuery]))
        XCTAssertNil(error.containedIn([.operationForbidden, .invalidQuery]))
    }
}
