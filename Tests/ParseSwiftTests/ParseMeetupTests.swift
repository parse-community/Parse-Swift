//
//  ParseMeetupTests.swift
//  ParseSwift
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseMeetupTests: XCTestCase {
    struct User: ParseUser {
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?
    }

    struct LoginSignupResponse: ParseUser {
        var objectId: String?
        var createdAt: Date?
        var sessionToken: String?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
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

    func testAuthenticationKeys() throws {
        let authData = ParseMeetup<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "token")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "token"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing", "access_token": "token"]
        let authDataMissingToken = ["id": "testing"]
        let authDataMissingId = ["access_token": "token"]

        XCTAssertTrue(ParseMeetup<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseMeetup<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataMissingToken))
        XCTAssertFalse(ParseMeetup<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataMissingId))
    }

    func testLogin() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ["id": "testing", "access_token": "token"]
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.meetup.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.meetup.login(id: "testing", accessToken: "token") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user, User.current)
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(user.meetup.isLinked)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginWrongKeys() throws {
        let expectation1 = XCTestExpectation(description: "Login")

        User.meetup.login(authData: ["id": "testing"]) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
