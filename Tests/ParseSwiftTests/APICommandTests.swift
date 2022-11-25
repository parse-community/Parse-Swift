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

        var originalData: Data?
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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
        }
    }

    func userLogin() {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try User.login(username: loginUserName, password: loginPassword)
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    func testOptionCacheHasher() throws {
        var options = API.Options()
        options.insert(.cachePolicy(.returnCacheDataDontLoad))
        XCTAssertFalse(options.contains(.usePrimaryKey))
        XCTAssertTrue(options.contains(.cachePolicy(.returnCacheDataDontLoad)))
        XCTAssertTrue(options.contains(.cachePolicy(.reloadRevalidatingCacheData)))
        options.insert(.usePrimaryKey)
        XCTAssertTrue(options.contains(.usePrimaryKey))
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
        let originalError = ParseError(code: .unknownError, message: "Could not decode")
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

    // This is how errors HTTP errors should typically come in
    func testErrorHTTP400JSON() {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
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

    //This is how errors HTTP errors should typically come in
    func testErrorHTTP500JSON() {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 500, delay: 0.0)
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

    func testErrorHTTPReturns400NoDataFromServer() {
        let originalError = ParseError(code: .unknownError, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(error: originalError) // Status code defaults to 400
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

    func testErrorHTTPReturns500NoDataFromServer() {
        let originalError = ParseError(code: .unknownError, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            var response = MockURLResponse(error: originalError)
            response.statusCode = 500
            return response
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

    func testApplicationIdHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Application-Id"], ParseSwift.configuration.applicationId)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Application-Id"],
                           ParseSwift.configuration.applicationId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testClientKeyHeader() throws {
        guard let clientKey = ParseSwift.configuration.clientKey else {
            throw ParseError(code: .unknownError, message: "Parse configuration should contain key")
        }

        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Client-Key"], clientKey)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Client-Key"],
                           clientKey)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPrimaryKeyHeader() throws {
        guard let primaryKey = ParseSwift.configuration.primaryKey else {
            throw ParseError(code: .unknownError, message: "Parse configuration should contain key")
        }

        let headers = API.getHeaders(options: [])
        XCTAssertNil(headers["X-Parse-Master-Key"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.usePrimaryKey]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Master-Key"],
                           primaryKey)
            XCTAssertEqual(ParseSwift.configuration.primaryKey,
                           primaryKey)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testSessionTokenHeader() throws {
        userLogin()
        guard let sessionToken = BaseParseUser.currentContainer?.sessionToken else {
            throw ParseError(code: .unknownError, message: "Parse current user should have session token")
        }

        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Session-Token"], sessionToken)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Session-Token"],
                           sessionToken)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceSessionTokenHeader() throws {

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.sessionToken("hello")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Session-Token"],
                           "hello")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationIdHeader() throws {
        guard let installationId = BaseParseInstallation.currentContainer.installationId else {
            throw ParseError(code: .unknownError, message: "Parse current user should have session token")
        }

        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Installation-Id"], installationId)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Installation-Id"],
                           installationId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceInstallationIdHeader() throws {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.installationId("hello")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Installation-Id"],
                           "hello")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContentHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"],
                           "application/json")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceContentHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.mimeType("application/html")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"],
                           "application/html")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContentLengthHeader() {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.fileSize("512")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Length"],
                           "512")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRemoveContentHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.removeMimeType]) {

        case .success(let request):
            XCTAssertNil(request.allHTTPHeaderFields?["Content-Type"])
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testClientVersionAPIMethod() {
        let clientVersion = API.clientVersion()
        XCTAssertTrue(clientVersion.contains(ParseConstants.sdk))
        XCTAssertTrue(clientVersion.contains(ParseConstants.version))

        let splitString = clientVersion
            .components(separatedBy: ParseConstants.sdk)
        XCTAssertEqual(splitString.count, 2)
        //If successful, will remove `swift` resulting in ""
        XCTAssertEqual(splitString[0], "")
        XCTAssertEqual(splitString[1], ParseConstants.version)

        //Test incorrect split
        let splitString2 = clientVersion
            .components(separatedBy: "hello")
        XCTAssertEqual(splitString2.count, 1)
        XCTAssertEqual(splitString2[0], clientVersion)
    }

    func testClientVersionHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Client-Version"], API.clientVersion())

        let post = API.Command<Level, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.Command<Level, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let patch = API.Command<Level, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch patch.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.Command<Level, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.Command<Level, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
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

        let patch = API.Command<Level, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch patch.prepareURLRequest(options: []) {

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

        let patch = API.NonParseBodyCommand<NoBody, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch patch.prepareURLRequest(options: []) {

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

    func testMetaDataHeader() {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.metadata(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["hello"], "world")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTagsHeader() {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.tags(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["hello"], "world")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContextHeader() {
        let headers = API.getHeaders(options: [])
        XCTAssertNil(headers["X-Parse-Cloud-Context"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch post.prepareURLRequest(options: [.context(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Cloud-Context"], "{\"hello\":\"world\"}")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}
