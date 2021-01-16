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
        // Those are required for Object
        var functionJobName: String
    }

    struct Cloud2: ParseCloud {
        // Those are required for Object
        var functionJobName: String

        // Your custom keys
        var customKey: String?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "https://localhost:1337/1") else {
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
        super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux)
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
        let response = AnyResultResponse(result: nil)

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
            XCTAssertEqual(functionResponse, AnyCodable())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFunction2() {
        var result: AnyCodable = ["hello": "world"]
        let response = AnyResultResponse(result: result)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                let encodedResult = try ParseCoding.jsonEncoder().encode(result)
                result = try ParseCoding.jsonDecoder().decode(AnyCodable.self, from: encodedResult)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let cloud = Cloud(functionJobName: "test")
            let functionResponse = try cloud.runFunction()
            guard let resultAsDictionary = functionResponse.value as? [String: String] else {
                XCTFail("Should have casted result to dictionary")
                return
            }
            XCTAssertEqual(resultAsDictionary, ["hello": "world"])
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

    func functionAsync(serverResponse: AnyCodable, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud(functionJobName: "test")
        cloud.runFunction(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let response):
                if serverResponse == AnyCodable() {
                    XCTAssertEqual(response, serverResponse)
                } else {
                    guard let resultAsDictionary = serverResponse.value as? [String: String] else {
                        XCTFail("Should have casted result to dictionary")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(resultAsDictionary, ["hello": "world"])
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testFunctionMainQueue() {
        let response = AnyResultResponse(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.functionAsync(serverResponse: AnyCodable(), callbackQueue: .main)
    }

    func testFunctionMainQueue2() {
        let result: AnyCodable = ["hello": "world"]
        let response = AnyResultResponse(result: result)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.functionAsync(serverResponse: result, callbackQueue: .main)
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
        let response = AnyResultResponse(result: nil)

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
            XCTAssertEqual(functionResponse, AnyCodable())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJob2() {
        let result: AnyCodable = ["hello": "world"]
        let response = AnyResultResponse(result: result)

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
            guard let resultAsDictionary = functionResponse.value as? [String: String] else {
                XCTFail("Should have casted result to dictionary")
                return
            }
            XCTAssertEqual(resultAsDictionary, ["hello": "world"])
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

    func jobAsync(serverResponse: AnyCodable, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let cloud = Cloud(functionJobName: "test")
        cloud.startJob(callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let response):
                if serverResponse == AnyCodable() {
                    XCTAssertEqual(response, serverResponse)
                } else {
                    guard let resultAsDictionary = serverResponse.value as? [String: String] else {
                        XCTFail("Should have casted result to dictionary")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(resultAsDictionary, ["hello": "world"])
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testJobMainQueue() {
        let response = AnyResultResponse(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.jobAsync(serverResponse: AnyCodable(), callbackQueue: .main)
    }

    func testJobMainQueue2() {
        let result: AnyCodable = ["hello": "world"]
        let response = AnyResultResponse(result: result)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        self.jobAsync(serverResponse: result, callbackQueue: .main)
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
