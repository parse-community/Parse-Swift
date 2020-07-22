//
//  ParseUserCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseUserCommandTests: XCTestCase {

    struct User: ParseSwift.UserType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseSwift.UserType {
        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?

        init() {
            self.createdAt = Date()
            self.updatedAt = Date()
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.password = "world"
            self.email = "hello@parse.com"
        }
    }

    let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
        var container = enc.container(keyedBy: DateEncodingKeys.self)
        try container.encode("Date", forKey: .type)
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .iso)
    })

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
    }

    func testFetchCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.fetchCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetch() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        userOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let fetched = try user.fetch()
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try user.fetch(options: [.useMasterKey])
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testSave() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        userOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try userOnServer.getEncoderWithoutSkippingKeys().encode(userOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let saved = try userOnServer.save()
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try userOnServer.save(options: [.useMasterKey])
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserSignUp() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
           let signedUp = try User.signup(username: loginResponse.username!, password: loginResponse.password!)
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNotNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserLogin() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoderWithoutSkippingKeys().encode(loginResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
           let loggedIn = try User.login(username: loginResponse.username!, password: loginResponse.password!)
            XCTAssertNotNil(loggedIn)
            XCTAssertNotNil(loggedIn.createdAt)
            XCTAssertNotNil(loggedIn.updatedAt)
            XCTAssertNotNil(loggedIn.email)
            XCTAssertNotNil(loggedIn.username)
            XCTAssertNotNil(loggedIn.password)
            XCTAssertNotNil(loggedIn.objectId)
            XCTAssertNotNil(loggedIn.sessionToken)
            XCTAssertNotNil(loggedIn.customKey)
            XCTAssertNil(loggedIn.ACL)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
