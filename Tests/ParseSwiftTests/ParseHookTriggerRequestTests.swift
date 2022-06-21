//
//  ParseHookTriggerRequestTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseHookTriggerRequestTests: XCTestCase {

    struct User: ParseCloudUser {

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
        var sessionToken: String?

        // Your custom keys
        var customKey: String?

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
        }
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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testCoding() async throws {
        let object = User(objectId: "geez")
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object)
        // swiftlint:disable:next line_length
        let expected = "{\"headers\":{\"yolo\":\"me\"},\"ip\":\"1.1.1.1\",\"master\":true,\"object\":{\"objectId\":\"geez\"}}"
        XCTAssertEqual(triggerRequest.description, expected)
    }

    func testGetLog() async throws {
        let object = User(objectId: "geez")
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object,
                                                                 log: AnyCodable("peace"))
        let log: String = try triggerRequest.getLog()
        XCTAssertEqual(log, "peace")
    }

    func testGetLogError() async throws {
        let object = User(objectId: "geez")
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object,
                                                                 log: AnyCodable("peace"))
        do {
            let _: Double = try triggerRequest.getLog()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("inferred"))
        }
    }

    func testGetContext() async throws {
        let object = User(objectId: "geez")
        let context = ["peace": "out"]
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object,
                                                                 context: AnyCodable(context))
        let requestContext: [String: String] = try triggerRequest.getContext()
        XCTAssertEqual(requestContext, context)
    }

    func testGetContextError() async throws {
        let object = User(objectId: "geez")
        let context = ["peace": "out"]
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object,
                                                                 context: AnyCodable(context))
        do {
            let _: Double = try triggerRequest.getContext()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("inferred"))
        }
    }

    func testOptions() throws {
        let object = User(objectId: "geez")
        let sessionToken = "dog"
        let installationId = "cat"
        let user = User(sessionToken: sessionToken)
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 user: user,
                                                                 installationId: installationId,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object)
        let options = API.Options([.useMasterKey])
        let requestOptions = triggerRequest.options()
        XCTAssertEqual(requestOptions, options)
        let triggerRequest2 = ParseHookTriggerRequest<User, User>(masterKey: false,
                                                                   user: user,
                                                                   installationId: installationId,
                                                                   ipAddress: "1.1.1.1",
                                                                   headers: ["yolo": "me"],
                                                                   object: object)
        let options2 = API.Options([.sessionToken(sessionToken),
            .installationId(installationId)])
        let requestOptions2 = triggerRequest2.options()
        XCTAssertEqual(requestOptions2, options2)
        let triggerRequest3 = ParseHookTriggerRequest<User, User>(masterKey: false,
                                                                  user: user,
                                                                  ipAddress: "1.1.1.1",
                                                                  headers: ["yolo": "me"],
                                                                  object: object)
        let options3 = API.Options([.sessionToken(sessionToken)])
        let requestOptions3 = triggerRequest3.options()
        XCTAssertEqual(requestOptions3, options3)
        let triggerRequest4 = ParseHookTriggerRequest<User, User>(masterKey: false,
                                                                  installationId: installationId,
                                                                  ipAddress: "1.1.1.1",
                                                                  headers: ["yolo": "me"],
                                                                  object: object)
        let options4 = API.Options([.installationId(installationId)])
        let requestOptions4 = triggerRequest4.options()
        XCTAssertEqual(requestOptions4, options4)
        let triggerRequest5 = ParseHookTriggerRequest<User, User>(masterKey: false,
                                                                  ipAddress: "1.1.1.1",
                                                                  headers: ["yolo": "me"],
                                                                  object: object)
        let options5 = API.Options()
        let requestOptions5 = triggerRequest5.options()
        XCTAssertEqual(requestOptions5, options5)
    }

    @MainActor
    func testHydrateUser() async throws {
        let sessionToken = "dog"
        let user = User(objectId: "objectId", sessionToken: sessionToken)
        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        var server = userOnServer
        let encoded = try ParseCoding.jsonEncoder().encode(server)
        //Get dates in correct format from ParseDecoding strategy
        server = try ParseCoding.jsonDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let object = User(objectId: "geez")
        let installationId = "cat"
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 user: user,
                                                                 installationId: installationId,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object)
        let requestHydrated = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                  user: server,
                                                                  installationId: installationId,
                                                                  ipAddress: "1.1.1.1",
                                                                  headers: ["yolo": "me"],
                                                                  object: object)
        let hydrated = try await triggerRequest.hydrateUser()
        XCTAssertEqual(hydrated, requestHydrated)
    }

    @MainActor
    func testHydrateUserError() async throws {
        let sessionToken = "dog"
        let user = User(objectId: "objectId", sessionToken: sessionToken)
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let object = User(objectId: "geez")
        let installationId = "cat"
        let triggerRequest = ParseHookTriggerRequest<User, User>(masterKey: true,
                                                                 user: user,
                                                                 installationId: installationId,
                                                                 ipAddress: "1.1.1.1",
                                                                 headers: ["yolo": "me"],
                                                                 object: object)
        do {
            _ = try await triggerRequest.hydrateUser()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }
}
#endif
