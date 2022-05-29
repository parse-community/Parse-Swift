//
//  ParseSchemaAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/29/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseSchemaAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject, ParseQueryScorable {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var isCounts: Bool?

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
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

        init() { }
        init(objectId: String) {
            self.objectId = objectId
        }
    }

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // provided by Role
        var name: String?
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

    let objectId = "1234"
    let user = User(objectId: "1234")

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

/*
    @MainActor
    func testCreate() async throws {
        MockURLProtocol.removeAll()

        var schema = ParseSchema<GameScore>()
        schema.fields
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let saved = try await installation.create()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }
 */
}
#endif
