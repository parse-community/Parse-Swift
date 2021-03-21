//
//  APICommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class APICommandTests: XCTestCase {

    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name = "First"
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

    func testExecuteCorrectly() {
        let originalObject = "test"
        MockURLProtocol.mockRequests { _ in
            do {
                return try MockURLResponse(string: originalObject, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let returnedObject =
                try API.NonParseBodyCommand<NoBody, String>(method: .GET,
                                                            path: .login,
                                                            params: nil,
                                                            mapper: { (data) -> String in
                    return try JSONDecoder().decode(String.self, from: data)
                }).execute(options: [])
            XCTAssertEqual(originalObject, returnedObject)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    //This is how errors from the server should typically come in
    func testErrorFromParseServer() {
        let originalError = ParseError(code: .unknownError, message: "Couldn't decode")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try JSONEncoder().encode(originalError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                XCTFail("Should encode error")
                return nil
            }
        }

        do {
            _ = try API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                            path: .login,
                                                            params: nil,
                                                            mapper: { (_) -> NoBody in
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

    //This is how errors HTTP errors should typically come in
    func testErrorHTTPJSON() {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100500
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 400, delay: 0.0)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        do {
            _ = try API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                            path: .login,
                                                            params: nil,
                                                            mapper: { (_) -> NoBody in
                throw parseError
            }).execute(options: [])

            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    //This is less common as the HTTP won't be able to produce ParseErrors directly, but used for testing
    func testErrorHTTPReturnsParseError1() {
        let originalError = ParseError(code: .invalidServerResponse, message: "Couldn't decode")
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(error: originalError)
        }
        do {
            _ = try API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                            path: .login,
                                                            params: nil,
                                                            mapper: { (_) -> NoBody in
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

    func testIdempodency() {
        let headers = API.getHeaders(options: [])
        XCTAssertNotNil(headers["X-Parse-Request-Id"])

        let post = API.Command<Level, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.Command<Level, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.Command<Level, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.Command<Level, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testIdempodencyNoParseBody() {
        let headers = API.getHeaders(options: [])
        XCTAssertNotNil(headers["X-Parse-Request-Id"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.NonParseBodyCommand<NoBody, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.NonParseBodyCommand<NoBody, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.NonParseBodyCommand<NoBody, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
