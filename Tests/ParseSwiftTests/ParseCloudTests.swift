//
//  ParseCloudTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/29/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseCloudTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct Cloud: ParseCloud {
        typealias ReturnType = String? // swiftlint:disable:this nesting

        // Those are required for Object
        var functionJobName: String
    }

    struct Cloud2: ParseCloud {
        typealias ReturnType = String? // swiftlint:disable:this nesting

        // Those are required for Object
        var functionJobName: String

        // Your custom keys
        var customKey: String?
    }

    struct Cloud3: ParseCloud {
        typealias ReturnType = [String: String] // swiftlint:disable:this nesting

        // Those are required for Object
        var functionJobName: String
    }

    struct AnyResultResponse<U: Codable>: Codable {
        let result: U
    }

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

    func testJSONEncoding() throws {
        let expected = ["functionJobName": "test"]
        let cloud = Cloud(functionJobName: "test")
        let encoded = try JSONEncoder().encode(cloud)
        let decoded = try JSONDecoder().decode([String: String].self, from: encoded)
        XCTAssertEqual(decoded, expected, "all keys should show up in JSONEncoder")
    }

    func testJSONEncoding2() throws {
        let expected = [
            "functionJobName": "test",
            "customKey": "parse"
        ]
        let cloud = Cloud2(functionJobName: "test", customKey: "parse")
        let encoded = try JSONEncoder().encode(cloud)
        let decoded = try JSONDecoder().decode([String: String].self, from: encoded)
        XCTAssertEqual(decoded, expected, "all keys should show up in JSONEncoder")
    }

    func testParseEncoding() throws {
        let expected = [String: String]()
        let cloud = Cloud(functionJobName: "test")
        let encoded = try ParseCoding.parseEncoder().encode(cloud, skipKeys: .cloud)
        let decoded = try JSONDecoder().decode([String: String].self, from: encoded)
        XCTAssertEqual(decoded, expected, "\"functionJobName\" key should be skipped by ParseEncoder")
    }

    func testParseEncoding2() throws {
        let expected = [
            "customKey": "parse"
        ]
        let cloud = Cloud2(functionJobName: "test", customKey: "parse")
        let encoded = try ParseCoding.parseEncoder().encode(cloud, skipKeys: .cloud)
        let decoded = try JSONDecoder().decode([String: String].self, from: encoded)
        XCTAssertEqual(decoded, expected, "\"functionJobName\" key should be skipped by ParseEncoder")
    }

    func testCallFunctionCommand() throws {
        let cloud = Cloud(functionJobName: "test")
        let command = cloud.runFunctionCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/functions/test")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertEqual(command.body?.functionJobName, "test")
    }

    func testCallFunctionWithArgsCommand() throws {
        let cloud = Cloud2(functionJobName: "test", customKey: "parse")
        let command = cloud.runFunctionCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/functions/test")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertEqual(command.body?.functionJobName, "test")
        XCTAssertEqual(command.body?.customKey, "parse")
    }

    func testFunction() {
        let response = AnyResultResponse<String?>(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let cloud = Cloud(functionJobName: "test")
            let functionResponse = try cloud.runFunction()
            XCTAssertNil(functionResponse)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFunction2() {
        var result = ["hello": "world"]
        let response = AnyResultResponse(result: result)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                let encodedResult = try ParseCoding.jsonEncoder().encode(result)
                result = try ParseCoding.jsonDecoder().decode([String: String].self, from: encodedResult)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let cloud = Cloud3(functionJobName: "test")
            let functionResponse = try cloud.runFunction()
            XCTAssertEqual(functionResponse, ["hello": "world"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFunctionError() {

        let parseError = ParseError(code: .scriptError, message: "Error: Invalid function")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let cloud = Cloud(functionJobName: "test")
            _ = try cloud.runFunction()
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func functionAsync(serverResponse: [String: String], callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud3(functionJobName: "test")
        cloud.runFunction(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let response):
                XCTAssertEqual(response, serverResponse)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testFunctionMainQueue() {
        let response = AnyResultResponse(result: ["hello": "world"])

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.functionAsync(serverResponse: ["hello": "world"], callbackQueue: .main)
    }

    func functionAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud(functionJobName: "test")
        cloud.runFunction(callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have thrown ParseError")
                expectation1.fulfill()

            case .failure(let error):
                XCTAssertEqual(error.code, parseError.code)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testFunctionMainQueueError() {
        let parseError = ParseError(code: .scriptError, message: "Error: Invalid function")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.functionAsyncError(parseError: parseError, callbackQueue: .main)
    }

    func testCallJobCommand() throws {
        let cloud = Cloud(functionJobName: "test")
        let command = cloud.startJobCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/jobs/test")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertEqual(command.body?.functionJobName, "test")
    }

    func testCallJobWithArgsCommand() throws {
        let cloud = Cloud2(functionJobName: "test", customKey: "parse")
        let command = cloud.startJobCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/jobs/test")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertEqual(command.body?.functionJobName, "test")
        XCTAssertEqual(command.body?.customKey, "parse")
    }

    func testJob() {
        let response = AnyResultResponse<String?>(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let cloud = Cloud(functionJobName: "test")
            let functionResponse = try cloud.startJob()
            XCTAssertNil(functionResponse)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJob2() {
        let response = AnyResultResponse(result: ["hello": "world"])

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let cloud = Cloud3(functionJobName: "test")
            let functionResponse = try cloud.startJob()
            XCTAssertEqual(functionResponse, response.result)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJobError() {

        let parseError = ParseError(code: .scriptError, message: "Error: Invalid function")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let cloud = Cloud(functionJobName: "test")
            _ = try cloud.startJob()
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func jobAsync(serverResponse: [String: String], callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud3(functionJobName: "test")
        cloud.startJob(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let response):
                XCTAssertEqual(response, serverResponse)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testJobMainQueue() {
        let response = AnyResultResponse(result: ["hello": "world"])

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.jobAsync(serverResponse: ["hello": "world"], callbackQueue: .main)
    }

    func jobAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud(functionJobName: "test")
        cloud.startJob(callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have thrown ParseError")
                expectation1.fulfill()

            case .failure(let error):
                XCTAssertEqual(error.code, parseError.code)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testJobMainQueueError() {
        let parseError = ParseError(code: .scriptError, message: "Error: Invalid function")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.jobAsyncError(parseError: parseError, callbackQueue: .main)
    }
} // swiftlint:disable:this file_length
