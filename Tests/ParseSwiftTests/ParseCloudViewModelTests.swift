//
//  ParseCloudViewModelTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/11/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(SwiftUI)
import Foundation
import XCTest
@testable import ParseSwift

class ParseCloudViewModelTests: XCTestCase {
    struct Cloud: ParseCloud {
        typealias ReturnType = String? // swiftlint:disable:this nesting

        // These are required by ParseObject
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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        try KeychainStore.shared.deleteAll()
        try ParseStorage.shared.deleteAll()
    }

    func testFunction() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.error = ParseError(code: .unknownError, message: "error")
        viewModel.runFunction()

        let expectation = XCTestExpectation(description: "Run Function")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFunctionError() {
        let response = ParseError(code: .unknownError, message: "Custom error")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.results = "Test"
        viewModel.runFunction()

        let expectation = XCTestExpectation(description: "Run Function")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.results, nil)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testJob() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.error = ParseError(code: .unknownError, message: "error")
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testViewModelStatic() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let cloud = Cloud(functionJobName: "test")
        let viewModel = Cloud.viewModel(cloud)
        viewModel.error = ParseError(code: .unknownError, message: "error")
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testJobError() {
        let response = ParseError(code: .unknownError, message: "Custom error")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.results = "Test"
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(viewModel.results, nil)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
#endif
