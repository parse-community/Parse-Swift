//
//  ParseErrorTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/16/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseErrorTests: XCTestCase {

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
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testEncode() throws {
        let code = -1
        let message = "testing ParseError"
        guard let encoded: Data = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code.rawValue, code)
        XCTAssertEqual(decoded.message, message)
        XCTAssertEqual(decoded.debugDescription, "ParseError code=\(code) error=\(message)")
        XCTAssertEqual(decoded.description, "ParseError code=\(code) error=\(message)")
    }

    func testEncodeOther() throws {
        let code = 2000
        let message = "testing ParseError"
        guard let encoded = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code, .other)
        XCTAssertEqual(decoded.message, message)
        XCTAssertEqual(decoded.debugDescription,
                       "ParseError code=\(ParseError.Code.other.rawValue) error=\(message) otherCode=\(code)")
        XCTAssertEqual(decoded.otherCode, code)
    }

    func testCompare() throws {
        let code = ParseError.Code.objectNotFound.rawValue
        let message = "testing ParseError"
        guard let encoded = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)

        let error: Error = decoded

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
